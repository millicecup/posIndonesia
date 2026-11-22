import json,re,struct,sys,tempfile,unittest
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/vision/demo'))
from recognizer import collect_asset_references

class AssetReferenceTests(unittest.TestCase):
    def fixture(self,root,pois,names):
        (root/'assets/data').mkdir(parents=True)
        (root/'assets/images/pois').mkdir(parents=True)
        (root/'assets/data/pois.json').write_text(json.dumps({'pois':pois}),encoding='utf8')
        for name in names:(root/'assets/images/pois'/name).touch()
    def test_every_active_collection_gallery_image_is_indexed(self):
        refs,excluded=collect_asset_references()
        indexed={r['reference']:r['app_poi_id'] for r in refs}
        pois=json.loads((ROOT/'assets/data/pois.json').read_text(encoding='utf8'))['pois']
        for p in pois:
            if not p.get('baseline',True):continue
            images=p.get('images',[])+[a for s in p.get('sections',[]) for a in s.get('images',[])]
            for image in images:
                if image.startswith('assets/images/pois/') and not re.fullmatch(r'p\d{2}_1\.png',Path(image).name,re.I):
                    self.assertEqual(indexed.get(image),p['id'])
        self.assertTrue(all(r['reference'].startswith('assets/images/pois/') for r in refs))
        self.assertTrue(all(x['reason']=='placeholder' for x in excluded))
    def test_new_folder_photos_are_included_but_placeholders_are_not(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);self.fixture(root,[{'id':'P01','name':'Museum','images':['assets/images/pois/p01_01.jpg']}],['p01_01.jpg','p01_02.jpg','p01_1.png'])
            refs,excluded=collect_asset_references(root)
            self.assertEqual({Path(r['reference']).name for r in refs},{'p01_01.jpg','p01_02.jpg'})
            self.assertEqual(excluded,[{'reference':'assets/images/pois/p01_1.png','reason':'placeholder'}])
    def test_current_metadata_takes_precedence_over_filename(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);self.fixture(root,[{'id':'P02','name':'Museum','images':['assets/images/pois/p01_01.jpg']}],['p01_01.jpg'])
            refs,_=collect_asset_references(root);self.assertEqual(refs[0]['app_poi_id'],'P02')
    def test_conflicting_metadata_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);self.fixture(root,[{'id':p,'name':p,'images':['assets/images/pois/p01_01.jpg']} for p in ['P01','P02']],['p01_01.jpg'])
            with self.assertRaisesRegex(ValueError,'lebih dari satu POI'):collect_asset_references(root)
    def test_unassigned_photo_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);self.fixture(root,[],['unknown.jpg'])
            with self.assertRaisesRegex(ValueError,'belum memiliki ID POI'):collect_asset_references(root)
    def test_native_compact_index_covers_the_catalog(self):
        folder=ROOT/'android/app/src/main/assets/jejakpos_sift'
        manifest=json.loads((folder/'manifest.json').read_text(encoding='utf8'))
        refs,_=collect_asset_references()
        self.assertEqual(manifest['sources'],refs)
        with (folder/'index.bin').open('rb') as stream:
            self.assertEqual(stream.read(8),b'JPSIFT02')
            count=struct.unpack('>i',stream.read(4))[0];self.assertEqual(count,len(refs))
            for ref in refs:
                size=struct.unpack('>H',stream.read(2))[0]
                self.assertEqual(stream.read(size).decode(),ref['app_poi_id'])
                width,height,n=struct.unpack('>iii',stream.read(12))
                self.assertTrue(width>0 and height>0 and n>=12)
                points=np.frombuffer(stream.read(n*8),dtype='>f4')
                self.assertEqual(len(points),n*2);self.assertTrue(np.isfinite(points).all())
                self.assertEqual(len(stream.read(n*128)),n*128)
            self.assertEqual(stream.read(),b'')
if __name__=='__main__':unittest.main()
