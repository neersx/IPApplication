using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainSiteControl)]
    public class SiteControlsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISiteControlCache _siteControlCache;

        static readonly CommonQueryParameters DefaultQueryParameters = new CommonQueryParameters
                                                                       {
                                                                           SortBy = "name",
                                                                           SortDir = "asc",
                                                                           Skip = 0,
                                                                           Take = 50
                                                                       };

        public SiteControlsController(IDbContext dbContext,
                                      IPreferredCultureResolver preferredCultureResolver,
                                      ITaskSecurityProvider taskSecurityProvider,
                                      ISiteControlCache siteControlCache)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (dbContext == null) throw new ArgumentNullException("preferredCultureResolver");
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _taskSecurityProvider = taskSecurityProvider;
            _siteControlCache = siteControlCache;
        }

        [HttpGet]
        [Route("api/configuration/sitecontrols/view")]
        public dynamic GetViewData()
        {
            var releases = _dbContext.Set<ReleaseVersion>()
                                     .OrderByDescending(r => r.Sequence)
                                     .Select(r => new {r.Id, value = r.VersionName});

            return new
                   {
                       releases,
                       canUpdateSiteControls = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSiteControl, ApplicationTaskAccessLevel.Modify)
                   };
        }

        [HttpGet]
        [Route("api/configuration/sitecontrols")]
        public PagedResults Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SiteControlSearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();

            var results = _dbContext.Set<SiteControl>().AsQueryable();

            if (!string.IsNullOrWhiteSpace(searchOptions.Text))
                results = results.SearchText(searchOptions, culture);

            results = results
                .Include(s => s.Components)
                .Include(s => s.Tags)
                .Include(s => s.ReleaseVersion);

            if (searchOptions.VersionId != null)
            {
                var releaseDate = _dbContext.Set<ReleaseVersion>().Single(r => r.Id == searchOptions.VersionId);
                results = results.Where(r => r.ReleaseVersion.ReleaseDate >= releaseDate.ReleaseDate);
            }

            if (searchOptions.ComponentIds.Any())
                results = results.Where(s => s.Components.Any(c => searchOptions.ComponentIds.Contains(c.Id)));

            if (searchOptions.TagIds.Any())
                results = results.Where(_ => _.Tags.Any(t => searchOptions.TagIds.Contains(t.Id)));

            var total = results.Count();

            var interim = results.OrderByProperty(MapColumnName(queryParameters.SortBy), queryParameters.SortDir)
                                 .Skip(queryParameters.Skip.Value)
                                 .Take(queryParameters.Take.Value)
                                 .Select(_ => new SiteControlInterim
                                              {
                                                  Id = _.Id,
                                                  Name = _.ControlId,
                                                  Description = DbFuncs.GetTranslation(_.SiteControlDescription, null, _.SiteControlDescriptionTId, culture),
                                                  Release = _.ReleaseVersion != null ? _.ReleaseVersion.VersionName : null,
                                                  StringValue = _.StringValue,
                                                  IntegerValue = _.IntegerValue,
                                                  BooleanValue = _.BooleanValue,
                                                  DecimalValue = _.DecimalValue
                                              }).ToArray();

            var resultIds = interim.Select(_ => _.Id).ToArray();

            var comps = _dbContext.Set<SiteControl>()
                                  .Include(_ => _.Components)
                                  .Where(_ => resultIds.Contains(_.Id))
                                  .Select(_ => new
                                               {
                                                   _.Id,
                                                   Components = _.Components.Select(c => DbFuncs.GetTranslation(c.ComponentName, null, c.ComponentNameTId, culture))
                                               }).ToArray();

            var data = interim.Select(_ => new
                                           {
                                               _.Id,
                                               _.Name,
                                               _.Description,
                                               _.Release,
                                               _.Value,
                                               Components = BuildComponents(_.Id, comps)
                                           });

            return new PagedResults(data, total);
        }

        static string BuildComponents(int id, IEnumerable<dynamic> comps)
        {
            var matched = comps.SingleOrDefault(_ => _.Id == id);
            if (matched == null)
                return null;

            return string.Join(", ", matched.Components);
        }

        [HttpGet]
        [Route("api/configuration/sitecontrols/{id}")]
        public dynamic Get(int id)
        {
            var culture = _preferredCultureResolver.Resolve();

            var canUpdate = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSiteControl, ApplicationTaskAccessLevel.Modify);

            var interim = from _ in _dbContext.Set<SiteControl>()
                          where _.Id == id
                          select new SiteControlInterim
                                 {
                                     Id = _.Id,
                                     Name = _.ControlId,
                                     Notes = canUpdate ? _.Notes : DbFuncs.GetTranslation(_.Notes, null, _.NotesTId, culture),
                                     IntegerValue = _.IntegerValue,
                                     DecimalValue = _.DecimalValue,
                                     StringValue = _.StringValue,
                                     BooleanValue = _.BooleanValue,
                                     InitialValue = _.InitialValue,
                                     Tags = _.Tags,
                                     DataType = _.DataType
                                 };

            if (!interim.Any())
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return interim.Single();
        }

        [HttpPut]
        [Route("api/configuration/sitecontrols")]
        public void Update(IEnumerable<SiteControlUpdateDetails> newValues)
        {
            var listUpdateCache = new List<string>();

            foreach (var item in newValues)
            {
                var s = _dbContext.Set<SiteControl>()
                                  .Include(_ => _.Tags)
                                  .Single(_ => _.Id == item.Id);

                s.UpdateValue(item.Value);
                s.Notes = item.Notes;

                s.Tags.Clear();
                var tagIdsToAdd = item.Tags.Select(_ => _.Id);
                var tagsToAdd = _dbContext.Set<Tag>().Where(_ => tagIdsToAdd.Contains(_.Id));
                s.Tags.AddRange(tagsToAdd);

                listUpdateCache.Add(s.ControlId);
            }

            _dbContext.SaveChanges();

            _siteControlCache.Clear(listUpdateCache.ToArray());
        }

        static string MapColumnName(string name)
        {
            name = (name ?? "name").ToLower();

            if ("name".Equals(name, StringComparison.OrdinalIgnoreCase))
            {
                return "ControlId";
            }

            switch (name)
            {
                case "name":
                    return "ControlId";
                case "description":
                    return "SiteControlDescription";
                case "release":
                    return "ReleaseVersion.Sequence";
            }
            return name;
        }
    }

    public class SiteControlInterim : ISiteControlDataTypeFormattable
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public string Description { get; set; }

        [JsonIgnore]
        public int? IntegerValue { get; set; }

        [JsonIgnore]
        public string StringValue { get; set; }

        [JsonIgnore]
        public bool? BooleanValue { get; set; }

        [JsonIgnore]
        public decimal? DecimalValue { get; set; }

        [JsonIgnore]
        public DateTime? DateValue { get; set; }
        
        public string InitialValue { get; set; }

        public string Notes { get; set; }

        public string Release { get; set; }

        public string DataType
        {
            get { return this.GetDataTypeName(_dataType); }
            set { _dataType = value; }
        }

        string _dataType;

        public ICollection<Tag> Tags { get; set; }

        public SiteControlInterim()
        {
            Tags = new Tag[0];
        }

        public object Value
        {
            get { return this.GetValue(_dataType); }
        }
    }
}