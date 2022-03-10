using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Ede.DataMapping.Mappings;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;
using Mapping = Inprotech.Web.Configuration.Ede.DataMapping.Mappings.Mapping;

namespace Inprotech.Web.Configuration.Ede.DataMapping
{
    [Authorize]
    [RoutePrefix("api/configuration/ede/datamapping")]
    [RequiresAccessTo(ApplicationTask.ConfigureDataMapping)]
    public class EdeMappingController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IMappingHandlerResolver _mappingHandlerResolver;
        readonly IMappingPersistence _mappingPersistence;
        readonly IConfigurableDataSources _configurableDataSources;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public EdeMappingController(IDbContext dbContext, IMappingHandlerResolver mappingHandlerResolver,
            IMappingPersistence mappingPersistence, IConfigurableDataSources configurableDataSources, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _mappingHandlerResolver = mappingHandlerResolver ?? throw new ArgumentNullException(nameof(mappingHandlerResolver));
            _mappingPersistence = mappingPersistence ?? throw new ArgumentNullException(nameof(mappingPersistence));
            _configurableDataSources = configurableDataSources ?? throw new ArgumentNullException(nameof(configurableDataSources));
            _preferredCultureResolver = preferredCultureResolver;
            _queryParameters = new CommonQueryParameters { SortBy = "inputDesc" };
        }

        [HttpGet]
        [NoEnrichment]
        [Route("datasource/{datasource}")]
        public dynamic ViewData(string dataSource)
        {
            DataSourceType source;
            if (string.IsNullOrWhiteSpace(dataSource)) throw new ArgumentNullException(nameof(dataSource));
            if (!Enum.TryParse(dataSource, true, out source)) throw new HttpResponseException(HttpStatusCode.NotFound);

            var structures = new short[0];
            IEnumerable<short> supportedBySource;
            if (_configurableDataSources.Retrieve().TryGetValue(source, out supportedBySource))
            {
                structures = supportedBySource.ToArray();
            }

            var culture = _preferredCultureResolver.Resolve();

            var mapStructures = _dbContext.Set<MapStructure>()
                                          .Where(_ => structures.Contains(_.Id))
                                          .Select(_ => DbFuncs.GetTranslation(_.Name, null, _.NameTid, culture))
                                          .OrderBy(s => s);
           
            return new
            {
                dataSource,
                displayText = Enum.TryParse(dataSource, true, out DataSourceType dataSourceType) ? ExternalSystems.DisplayText(dataSourceType) : string.Empty,
                structures = mapStructures
            };
        }
       
        [HttpGet]
        [NoEnrichment]
        [Route("datasource/{datasource}/structure/{structure}/mappings")]
        public dynamic Fetch(string dataSource, string structure, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                                 = null)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters);

            if (string.IsNullOrWhiteSpace(dataSource)) throw new ArgumentNullException(nameof(dataSource));
            if (string.IsNullOrWhiteSpace(structure)) throw new ArgumentNullException(nameof(structure));

            var systemId = ExternalSystems.Id(dataSource);

            var s = _dbContext.Set<MapStructure>()
                .Include(_ => _.MapScenarios)
                .SingleOrDefault(_ => _.Name == structure);

            if (s == null || !systemId.HasValue || s.MapScenarios.All(_ => _.SystemId != systemId))
                return new HttpResponseException(HttpStatusCode.NotFound);

            var mappings = _mappingHandlerResolver.Resolve(s.Id).FetchBy(systemId, s.Id);
            var enumerable = mappings as Mapping[] ?? mappings.ToArray();
            var count = enumerable.Length;

            var executedResults = enumerable.Skip(extendedQueryParams.Skip.GetValueOrDefault())
                                           .Take(extendedQueryParams.Take.GetValueOrDefault());

            var canIgnoreUnmapped = s.MapScenarios.Single(_ => _.SystemId == systemId).IgnoreUnmapped;

            return
                new
                {
                    StructureDetails = new
                    {
                        IgnoreUnmapped = canIgnoreUnmapped,
                        Mappings = new PagedResults(executedResults, count)
                    }
                };
        }

        [HttpGet]
        [NoEnrichment]
        [Route("datasource/{datasource}/mapping/{id}")]
        public dynamic Get(string dataSource, int id)
        {
            var dataMapping = _dbContext.Set<InprotechKaizen.Model.Ede.DataMapping.Mapping>()
                                    .SingleOrDefault(_ => _.Id == id);

            if (dataMapping == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var systemId = ExternalSystems.Id(dataSource);

            if (!systemId.HasValue)
                return new HttpResponseMessage(HttpStatusCode.NotFound);

            var mapping = _mappingHandlerResolver.Resolve(dataMapping.StructureId).FetchBy(systemId, dataMapping.StructureId).Single(_ => _.Id == id);

            var e = (EventMapping)mapping;
            var eventData = _dbContext.Set<Event>().SingleOrDefault(_ => _.Id == e.Output.Key);

            return
                new
                {
                    Description = mapping.InputDesc,
                    mapping.Id,
                    Ignore = mapping.NotApplicable,
                    Event = eventData != null ? new Picklists.Event
                    {
                        Key = eventData.Id,
                        Code = eventData.Code,
                        Value = eventData.Description
                    }
                    : null
                };
        }

        [HttpPost]
        [Route("")]
        public dynamic Post(JObject saveModel)
        {
            var payload = ExtractPayload(saveModel);

            if (payload.systemId == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            if (payload.mapStructure == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var mapping = saveModel["mapping"]
                .ToObject(_mappingHandlerResolver.Resolve(payload.mapStructure.Id).MappingType);

            IEnumerable<string> errors;

            int? newId ;
            if (!_mappingPersistence.Add((Mapping)mapping, payload.mapStructure.Id, payload.systemId, out errors, out newId))
            {
                return new
                {
                    Result = "error",
                    Errors = errors
                };
            }

            return new
            {
                Result = "success",
                newId
            };
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Put(JObject saveModel)
        {
            var payload = ExtractPayload(saveModel);

            if (payload.systemId == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            if (payload.mapStructure == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var mapping = saveModel["mapping"]
                .ToObject(_mappingHandlerResolver.Resolve(payload.mapStructure.Id).MappingType);

            IEnumerable<string> errors;
            if (!_mappingPersistence.Update((Mapping)mapping, payload.mapStructure.Id, payload.systemId, out errors))
            {
                return new
                {
                    Result = "error",
                    Errors = errors
                };
            }

            return new { Result = "success" };
        }

        public dynamic ExtractPayload(JObject saveModel)
        {
            if (saveModel == null) throw new ArgumentNullException(nameof(saveModel));

            var dataSource = (string)saveModel["systemId"];
            var systemId = ExternalSystems.Id(dataSource);

            var structure = (string)saveModel["structureId"];
            var mapStructure = _dbContext.Set<MapStructure>()
                              .Include(_ => _.MapScenarios)
                              .SingleOrDefault(_ => _.Name == structure);

            return new
            {
                systemId,
                mapStructure
            };
        }

        [HttpPost]
        [Route("delete")]
        public dynamic Delete(DeleteRequestModel deleteRequestModel)
        {
            if(deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            foreach (var id in deleteRequestModel.Ids)
            {
                _mappingPersistence.Delete(id);
            }

            return new { Result = "success" };
        }
    }
}
