using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Cases.PriorArt
{
    public interface IAsyncPriorArtEvidenceFinder
    {
        Task<SearchResult> Find(SearchRequest request, SearchResultOptions options);
    }
}