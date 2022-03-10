using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Search.Export
{
    public class ImageSettingsLoader : IImageSettings
    {
        internal Dictionary<int, ImageData> _images;
        readonly IDbContext _dbContext;
        const string ImageColumnFormat = "Image Key";

        public ImageSettingsLoader(IDbContext dbContext)
        {
            _dbContext = dbContext;
            _images = new Dictionary<int, ImageData>();
        }

        public ImageData FindImageByKey(int imageKey)
        {
            if (!_images.TryGetValue(imageKey, out ImageData imageData)) return null;
            return imageData;
        }

        public void Load(SearchPresentation searchPresentation, IEnumerable<Dictionary<string, object>> data)
        {
            var columnsWithImageKeyFormat =
                searchPresentation.FindAllColumnFormatByFormat(ImageColumnFormat).ToArray();

            var imageKeys = new List<int>();
            foreach (var row in data)
            {
                foreach (var format in columnsWithImageKeyFormat)
                {
                    if (format != null
                             && row.TryGetValue(format.Id, out var val)
                             && val != null)
                    {
                        imageKeys.Add(Convert.ToInt32(val));
                    }
                }
            }
            LoadImages(imageKeys.Distinct());
        }

        void LoadImages(IEnumerable<int> images)
        {
            _images = _dbContext.Set<Image>()
                                    .Where(i => images.Contains(i.Id))
                                    .ToArray()
                                    .ToDictionary(k => k.Id, v => new ImageData
                                    {
                                        Data = v.ImageData,
                                        ContentType = v.Detail.ContentType
                                    });
        }
    }
}
