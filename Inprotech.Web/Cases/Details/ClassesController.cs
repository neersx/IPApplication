using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Jurisdictions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class ClassesController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICommonQueryService _commonQueryService;
        readonly IClassesTextResolver _classesTextResolver;
        readonly ICaseClasses _caseClassesResolver;
        readonly ICaseTextSection _caseTextSection;
        
        public ClassesController(IDbContext dbContext, ICommonQueryService commonQueryService,ICaseClasses caseClassesResolver, IClassesTextResolver classesTextResolver, ICaseTextSection caseTextSection)
        {
            _dbContext = dbContext;
            _commonQueryService = commonQueryService;
            _classesTextResolver = classesTextResolver;
            _caseClassesResolver = caseClassesResolver;
            _caseTextSection = caseTextSection;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/classesSummary")]
        public dynamic CaseClassesSummary(int caseKey)
        {
            var @case = _dbContext.Set<Case>()
                                  .Single(v => v.Id == caseKey);

            if (@case == null) throw new ArgumentNullException(nameof(caseKey));

            var itemCount = 0;
            if (@case.PropertyType != null && @case.PropertyType.AllowSubClass == 2)
            {
                  itemCount = _dbContext.Set<ClassItem>().Join(_dbContext.Set<CaseClassItem>(), ci => ci.Id, cci => cci.ClassItemId, (ci, cci) => new { ci, cci })
                                         .Count(x => x.cci.CaseId == caseKey && x.ci.LanguageCode == null);
            }

            var classes = new CaseViewClasses
            {
                Id = @case.Id,
                LocalClasses = @case.LocalClasses.Sort(),
                TotalLocal = string.IsNullOrEmpty(@case.LocalClasses) ? 0 : @case.LocalClasses.Split(',').Length,
                InternationalClasses = @case.IntClasses.Sort(),
                TotalInternational = string.IsNullOrEmpty(@case.IntClasses) ? 0 : @case.IntClasses.Split(',').Length,
                TotalItem = itemCount
            };

            return classes;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/classesDetails")]
        public PagedResults CaseClassesDetails(int caseKey,
                                                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                              CommonQueryParameters queryParameters)
        {
            var @case = _dbContext.Set<Case>().
                                Single(v => v.Id == caseKey);

            if (@case == null) throw new ArgumentNullException(nameof(caseKey));

            if (string.IsNullOrEmpty(@case.LocalClasses))
                return new PagedResults(Enumerable.Empty<object>(), 0);

            var filtered = _caseClassesResolver.Get(@case);

            var results = filtered.Select(_ => new CaseClasses
            {
                Class = _.Class,
                InternationalEquivalent = _.IntClass,
                SubClass = _.SubClass
            }).ToArray();

            PopulateClassDetails(caseKey, results);

            if (string.IsNullOrEmpty(queryParameters.SortBy))
            {
                results = results.OrderByNumeric("Class", "asc")
                                 .ThenByNumeric("SubClass", "asc").ToArray();

                return new PagedResults(results, results.Length);
            }

            return new PagedResults(_commonQueryService.GetSortedPage(results, queryParameters),
                                    results.Length);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/{classKey}/classTexts")]
        public async Task<IEnumerable<CaseTextData>> ClassTexts(int caseKey, string classKey)
        {
            return await _caseTextSection.GetClassAndText(caseKey, classKey);
        }

        void PopulateClassDetails(int caseKey, CaseClasses[] results)
        {
            var classesFirstUse = _dbContext.Set<ClassFirstUse>().Where(_ => _.CaseId == caseKey).AsQueryable();

            results.PopulateClassFirstUse(classesFirstUse);

            results.PopulateGsText(_classesTextResolver, caseKey);
        }

        public class CaseClasses
        {
            public string Class { get; set; }
            public string SubClass { get; set; }
            public string InternationalEquivalent { get; set; }
            public string GsText { get; set; }
            public DateTime? DateFirstUse { get; set; }
            public DateTime? DateFirstUseInCommerce { get; set; }
            public bool HasMultipleLanguageClassText { get; set; }
        }

        public class CaseViewClasses
        {
            public int Id { get; set; }
            public string LocalClasses { get; set; }
            public int TotalLocal { get; set; }
            public string InternationalClasses { get; set; }
            public int TotalInternational { get; set; }
            public int TotalItem { get; set; }
        }
    }

    public static class CaseClassExtensions
    {
        public static IEnumerable<ClassesController.CaseClasses> PopulateClassFirstUse(this IEnumerable<ClassesController.CaseClasses> caseClasses,
                                                                    IQueryable<ClassFirstUse> classesFirstUse)
        {
            var populateClassFirstUse = caseClasses as ClassesController.CaseClasses[] ?? caseClasses.ToArray();
            foreach (var caseClass in populateClassFirstUse)
            {
                var classFirstUse = classesFirstUse
                                        .SingleOrDefault(cfu => cfu.Class.Equals(caseClass.Class));
                if (classFirstUse != null)
                {
                    caseClass.DateFirstUse = classFirstUse.FirstUsedDate;
                    caseClass.DateFirstUseInCommerce = classFirstUse.FirstUsedInCommerceDate;
                }
            }

            return populateClassFirstUse;
        }

        public static IEnumerable<ClassesController.CaseClasses> PopulateGsText(this IEnumerable<ClassesController.CaseClasses> caseClasses,
                                                                                        IClassesTextResolver classesTextResolver, int caseId)
        {
            var populateGsText = caseClasses as ClassesController.CaseClasses[] ?? caseClasses.ToArray();
            foreach (var caseClass in populateGsText)
            {
                var @class = string.IsNullOrEmpty(caseClass.SubClass) ?
                                        caseClass.Class : caseClass.Class + "." + caseClass.SubClass;

                var caseText = classesTextResolver.Resolve(@class, caseId);
                caseClass.GsText = caseText.GsText;
                caseClass.HasMultipleLanguageClassText = caseText.HasMultipleLanguageClassText;
            }

            return populateGsText;
        }
    }
}
