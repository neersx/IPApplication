using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Autofac.Features.Metadata;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Properties;

namespace InprotechKaizen.Model.Components.Cases.PriorArt
{
    public interface IConcurrentPriorArtEvidenceFinder
    {
        Task<SearchResult>[] Find(SearchRequest request, SearchResultOptions options);
    }

    public class ConcurrentPriorArtEvidenceFinder : IConcurrentPriorArtEvidenceFinder
    {
        readonly Autofac.ILifetimeScope _lifetimeScope;
        readonly ILogger<ConcurrentPriorArtEvidenceFinder> _logger;
        readonly string[] _finderNames;

        public ConcurrentPriorArtEvidenceFinder(
            Autofac.ILifetimeScope lifetimeScope,
            IEnumerable<Meta<Func<IAsyncPriorArtEvidenceFinder>>> finderMetadata, 
            ILogger<ConcurrentPriorArtEvidenceFinder> logger)
        {
            _lifetimeScope = lifetimeScope;
            _logger = logger;
            _finderNames = finderMetadata.Select(finder => (string) finder.Metadata["Name"]).ToArray();
        }
        
        public Task<SearchResult>[] Find(SearchRequest request, SearchResultOptions options)
        {
            return _finderNames.Select(finder => CreateFinderTask(finder, request, options)).ToArray();
        }
        
        Task<SearchResult> CreateFinderTask(string finderName, SearchRequest request, SearchResultOptions options)
        {
            var scope = _lifetimeScope.BeginLifetimeScope();
            var finder = scope.ResolveKeyed<IAsyncPriorArtEvidenceFinder>(finderName);
            return DispatchAsyncFinder(finder, finderName, request, options);
        }

        Task<SearchResult> DispatchAsyncFinder(IAsyncPriorArtEvidenceFinder finder, string finderName, SearchRequest request, SearchResultOptions options)
        {
            try
            {
                return finder.Find(request, options)
                             .OnException(e => AggregateExceptionToSearchResult(finderName, e), _logger);
            }
            catch(Exception ex)
            {
                if(ex.IsFatal())
                    throw;

                _logger.Exception(ex);
            }

            return Task.Run<SearchResult>(() => SearchResult.ForErrors(finderName, Resources.PriorArtEvidenceFinderError));
        }

        static SearchResult AggregateExceptionToSearchResult(string finderName, AggregateException exception)
        {
            return SearchResult.ForErrors(
                                          finderName,
                                          exception.InnerException is TimeoutException
                                              ? Resources.PriorArtEvidenceFinderTimedOut
                                              : Resources.PriorArtEvidenceFinderError);
        }
    }
}