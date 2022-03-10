using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Search.Export;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Integration.Search.Export
{
     public class ImageSettingsLoaderFacts : FactBase
     {
        public class LoadMethod : FactBase
        {
            readonly List<Dictionary<string,object>> _rowData = new List<Dictionary<string, object>>();
            readonly SearchPresentation _searchPresentation = new SearchPresentation();

            void SetupData() 
            {
                var imageDetail = new ImageDetail {ImageId = 1, ContentType = "images/png"}.In(Db);
                new Image
                {
                    ImageData = new byte[] { },
                    Detail = imageDetail
                }.In(Db);
                var imageDetail2 = new ImageDetail {ImageId = 2, ContentType = "images/png"}.In(Db);
                new Image
                {
                    ImageData = new byte[] { },
                    Detail = imageDetail2
                }.In(Db);

                var images = Db.Set<Image>().ToList(); 
                var first = new Dictionary<string, object>
                {
                    {"ImageData_11", images.First().Id}, {"RowKey", 1}
                };
                _rowData.Add(first);

                var second = new Dictionary<string, object>
                {
                    {"ImageData_11", images.Last().Id}, {"RowKey", 2}
                };
                _rowData.Add(second); 

                _searchPresentation.ColumnFormats = new List<ColumnFormat> {new ColumnFormat {Format = "Image Key", Id = "ImageData_11", Title = "Device"}};
            }
            
            [Fact]
            public void ShouldLoadAllTheAvailableImages()
            {
                SetupData();

                var j = new ImageSettingsLoader(Db);

                j.Load(_searchPresentation, _rowData);

                Assert.Equal(2, j._images.Count);

            }
        }

        public class FindMethod : FactBase
        {
            [Fact]
            public void ShouldReturnTheImageFromImagesCollection()
            {
                var j = new ImageSettingsLoader(Db);
                var imagesData = new Dictionary<int, ImageData> {{1, new ImageData()}};
                j._images = imagesData;

                var image = j.FindImageByKey(1);

                Assert.NotNull(image);
            }

            [Fact]
            public void ShouldNotReturnTheImageFromImagesCollection()
            {
                var j = new ImageSettingsLoader(Db);
                var imagesData = new Dictionary<int, ImageData> {{1, new ImageData()}};
                j._images = imagesData;

                var image = j.FindImageByKey(2);

                Assert.Null(image);
            }
        }
     }
}
