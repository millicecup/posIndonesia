package id.jejakpos.jejakpos;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.*;
import org.opencv.features2d.*;
import org.opencv.calib3d.Calib3d;
import org.opencv.imgproc.Imgproc;

/** Same feature descriptors and acceptance gates as the Python demo. No network. */
public final class SiftVision {
    private static final class Reference {
        String id; int width,height; Point[] points; Mat descriptors;
    }
    private final List<Reference> references = new ArrayList<>();
    private SIFT sift;
    private DescriptorMatcher matcher;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private static final Handler main = new Handler(Looper.getMainLooper());
    public static void register(Context context, FlutterEngine engine) {
        SiftVision recognizer = new SiftVision();
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "id.jejakpos/sift_vision")
            .setMethodCallHandler((call,result) -> {
                if (!call.method.equals("initialize") && !call.method.equals("recognize")) { result.notImplemented(); return; }
                recognizer.worker.execute(() -> {
                    try {
                        Object response;
                        if (call.method.equals("initialize")) {
                            recognizer.initialize(context.getApplicationContext());
                            response = recognizer.references.size();
                        } else {
                            byte[] bytes = call.argument("bytes");
                            Number width=call.argument("width"),height=call.argument("height"),stride=call.argument("stride"),pixelStride=call.argument("pixelStride"),rotation=call.argument("rotation");
                            if(bytes==null || width==null || height==null || stride==null || pixelStride==null || rotation==null) throw new IllegalArgumentException("Incomplete camera frame");
                            response=recognizer.recognize(bytes,width.intValue(),height.intValue(),stride.intValue(),pixelStride.intValue(),rotation.intValue());
                        }
                        main.post(() -> result.success(response));
                    } catch(Exception e) { main.post(() -> result.error("sift_failed", e.getMessage(), null)); }
                });
            });
    }
    public void initialize(Context context) throws IOException {
        if(sift!=null)return;
        if(!OpenCVLoader.initLocal())throw new IOException("OpenCV runtime tidak dapat dimuat");
        List<Reference> loaded=new ArrayList<>();
        try(DataInputStream input=new DataInputStream(new BufferedInputStream(context.getAssets().open("jejakpos_sift/index.bin")))) {
            byte[] magic=new byte[8];input.readFully(magic);
            boolean compact=Arrays.equals(magic,"JPSIFT02".getBytes("UTF-8"));
            if(!compact && !Arrays.equals(magic,"JPSIFT01".getBytes("UTF-8")))throw new IOException("Indeks SIFT tidak sesuai");
            int count=input.readInt();
            if(count<1 || count>500)throw new IOException("Jumlah referensi tidak valid");
            for(int i=0;i<count;i++) {
                Reference ref=new Reference();ref.id=input.readUTF();ref.width=input.readInt();ref.height=input.readInt();int n=input.readInt();
                if(n<12 || n>10000)throw new IOException("Jumlah fitur tidak valid");
                ref.points=new Point[n];for(int j=0;j<n;j++)ref.points[j]=new Point(input.readFloat(),input.readFloat());
                float[] data=new float[n*128];
                if(compact) {
                    byte[] packed=new byte[data.length];input.readFully(packed);
                    for(int j=0;j<data.length;j++)data[j]=packed[j]&0xff;
                } else {
                    for(int j=0;j<data.length;j++)data[j]=input.readFloat();
                }
                ref.descriptors=new Mat(n,128,CvType.CV_32F);ref.descriptors.put(0,0,data);loaded.add(ref);
            }
        } catch(IOException e) {for(Reference r:loaded)r.descriptors.release();throw e;}
        references.addAll(loaded);sift=SIFT.create(2200);matcher=DescriptorMatcher.create(DescriptorMatcher.FLANNBASED);
    }
    public Map<String,Object> recognize(byte[] bytes,int width,int height,int stride,int pixelStride,int rotation) {
        if(sift==null)throw new IllegalStateException("SIFT belum siap");
        if(width<1 || height<1 || width>4096 || height>4096 || stride<1 || pixelStride<1 || (long)(height-1)*stride+(long)(width-1)*pixelStride>=bytes.length)throw new IllegalArgumentException("Frame tidak valid");
        Mat gray=new Mat(height,width,CvType.CV_8U);
        byte[] contiguous=new byte[width*height];for(int y=0;y<height;y++)for(int x=0;x<width;x++)contiguous[y*width+x]=bytes[y*stride+x*pixelStride];
        gray.put(0,0,contiguous);
        Mat oriented=new Mat();int turn=((rotation%360)+360)%360;
        if(turn==90)Core.rotate(gray,oriented,Core.ROTATE_90_CLOCKWISE);
        else if(turn==180)Core.rotate(gray,oriented,Core.ROTATE_180);
        else if(turn==270)Core.rotate(gray,oriented,Core.ROTATE_90_COUNTERCLOCKWISE);
        else gray.copyTo(oriented);
        gray.release();
        try {return recognizeGray(oriented);} finally {oriented.release();}
    }
    public Map<String,Object> recognizeGray(Mat input) {
        long started=System.nanoTime();
        Mat gray=new Mat(), descriptors=new Mat(),emptyMask=new Mat();MatOfKeyPoint keypoints=new MatOfKeyPoint();
        List<Map<String,Object>> candidates=new ArrayList<>();
        try {
            double scale=Math.min(1,960.0/Math.max(input.cols(),input.rows()));
            Imgproc.resize(input,gray,new Size(Math.round(input.cols()*scale),Math.round(input.rows()*scale)));
            sift.detectAndCompute(gray,emptyMask,keypoints,descriptors);
            KeyPoint[] query=keypoints.toArray();
            if(!descriptors.empty() && descriptors.rows()>=12) for(Reference ref:references) {
                List<MatOfDMatch> pairs=new ArrayList<>();
                try {
                    matcher.knnMatch(ref.descriptors,descriptors,pairs,2);
                    Map<Integer,DMatch> unique=new HashMap<>();
                    for(MatOfDMatch pair:pairs) {
                        DMatch[] matches=pair.toArray();
                        if(matches.length==2 && matches[0].distance<0.7*matches[1].distance) {
                            DMatch m=matches[0],old=unique.get(m.trainIdx);
                            if(old==null || m.distance<old.distance)unique.put(m.trainIdx,m);
                        }
                    }
                    if(unique.size()<12)continue;
                    List<Point> srcList=new ArrayList<>(),dstList=new ArrayList<>();
                    for(DMatch m:unique.values()){srcList.add(ref.points[m.queryIdx]);dstList.add(query[m.trainIdx].pt);}
                    Map<String,Object> candidate=verify(ref,srcList,dstList,gray.cols(),gray.rows());
                    if(candidate!=null)candidates.add(candidate);
                } finally {for(MatOfDMatch pair:pairs)pair.release();}
            }
            candidates.sort((a,b)->Double.compare(((Number)b.get("score")).doubleValue(),((Number)a.get("score")).doubleValue()));
            Map<String,Object> best=candidates.isEmpty()?null:candidates.get(0);boolean ambiguous=false;
            if(best!=null)for(Map<String,Object> c:candidates)if(!c.get("poiId").equals(best.get("poiId"))){ambiguous=((Number)c.get("score")).doubleValue()>=((Number)best.get("score")).doubleValue()*0.8;break;}
            Map<String,Object> result=new HashMap<>();result.put("status",ambiguous?"ambiguous":best==null?"unknown":"recognized");result.put("match",ambiguous?null:best);result.put("elapsedMs",(System.nanoTime()-started)/1000000);return result;
        } finally {gray.release();descriptors.release();emptyMask.release();keypoints.release();}
    }
    private Map<String,Object> verify(Reference ref,List<Point> srcList,List<Point> dstList,int w,int h) {
        MatOfPoint2f src=new MatOfPoint2f(),dst=new MatOfPoint2f(),corners=new MatOfPoint2f(),quad=new MatOfPoint2f();
        Mat mask=new Mat(),H=null;MatOfPoint contour=new MatOfPoint(),inlierContour=new MatOfPoint(),hullContour=new MatOfPoint();MatOfInt hull=new MatOfInt();
        try {
            src.fromList(srcList);dst.fromList(dstList);H=Calib3d.findHomography(src,dst,Calib3d.RANSAC,4,mask);
            if(H.empty() || mask.empty())return null;
            byte[] flags=new byte[(int)mask.total()];mask.get(0,0,flags);List<Point> inside=new ArrayList<>();for(int i=0;i<flags.length;i++)if(flags[i]!=0)inside.add(srcList.get(i));
            int n=inside.size();double ratio=(double)n/srcList.size();if(n<12 || ratio<0.4)return null;
            corners.fromArray(new Point(0,0),new Point(ref.width,0),new Point(ref.width,ref.height),new Point(0,ref.height));Core.perspectiveTransform(corners,quad,H);
            Point[] polygon=quad.toArray();for(Point p:polygon)if(!Double.isFinite(p.x)||!Double.isFinite(p.y)||p.x < -w||p.x > 2*w||p.y < -h||p.y > 2*h)return null;
            contour.fromArray(polygon);if(!Imgproc.isContourConvex(contour))return null;
            double area=Math.abs(Imgproc.contourArea(contour));if(area<0.008*w*h || area>2.0*w*h)return null;
            inlierContour.fromList(inside);Imgproc.convexHull(inlierContour,hull);List<Point> hullPoints=new ArrayList<>();for(int i:hull.toArray())hullPoints.add(inside.get(i));hullContour.fromList(hullPoints);
            if(Math.abs(Imgproc.contourArea(hullContour))/(ref.width*(double)ref.height)<0.015)return null;
            Map<String,Object> result=new HashMap<>();result.put("poiId",ref.id);result.put("inliers",n);result.put("inlierRatio",ratio);result.put("score",n*ratio);return result;
        } finally {src.release();dst.release();corners.release();quad.release();mask.release();if(H!=null)H.release();contour.release();inlierContour.release();hullContour.release();hull.release();}
    }
}
