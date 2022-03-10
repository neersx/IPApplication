using System.Linq;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt.ExistingPriorArtFinders
{
    public interface IExistingPriorArtFinder
    {
        IQueryable<InprotechKaizen.Model.PriorArt.PriorArt> GetExistingPriorArt(SearchRequest request);
    }
}