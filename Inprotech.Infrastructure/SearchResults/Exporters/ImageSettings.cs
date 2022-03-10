using Inprotech.Infrastructure.Web;
using System.Collections.Generic;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public interface IImageSettings
    {
        void Load(SearchPresentation searchPresentation, IEnumerable<Dictionary<string, object>> data);
        ImageData FindImageByKey(int imageKey);
    }
}
