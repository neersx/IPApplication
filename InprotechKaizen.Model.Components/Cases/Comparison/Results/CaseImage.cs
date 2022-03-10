using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    //All ids should be encrypted
    public class CaseImage
    {
        public CaseImage()
        {
            CaseImageIds = Enumerable.Empty<string>();
        }

        public IEnumerable<string> CaseImageIds { get; set; }

        public string DownloadedThumbnailId { get; set; }

        public string DownloadedImageId { get; set; }
    }
}