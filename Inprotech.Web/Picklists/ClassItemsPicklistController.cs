using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/classitems")]
    public class ClassItemPickListController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IClassItemsPicklistMaintenance _classItemPicklistMaintenance;

        public ClassItemPickListController(IDbContext dbContext, IClassItemsPicklistMaintenance classItemPicklistMaintenance)
        {
            _dbContext = dbContext;
            _classItemPicklistMaintenance = classItemPicklistMaintenance;
            
            _queryParameters = new CommonQueryParameters();
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(ClassItem), ApplicationTask.MaintainJurisdiction)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route("subclasses/{countryCode}/{propertyType}/{class}")]
        public IEnumerable<dynamic> SubClasses(string countryCode, string propertyType, string @class)
        {
            if (string.IsNullOrEmpty(countryCode)
                || string.IsNullOrEmpty(propertyType)
                || string.IsNullOrEmpty(@class))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var relevant = _dbContext.Set<TmClass>().Where(_ => _.CountryCode.Equals(countryCode)
                                                               && _.PropertyType.Equals(propertyType)
                                                               && _.Class.Equals(@class)
                                                               && !string.IsNullOrEmpty(_.SubClass));

            var subClasses = relevant.Select(_ => _.SubClass).ToArray().OrderBy(_ => _ , new NumericComparer());
            return subClasses;
        }

        [HttpGet]
        [Route("{classItemId}")]
        [PicklistPayload(typeof(ClassItemSaveDetails))]
        public ClassItemSaveDetails ClassItem(int classItemId)
        {
            return _classItemPicklistMaintenance.Get(classItemId);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public dynamic Add(ClassItemSaveDetails classItemSaveDetails)
        {
            return _classItemPicklistMaintenance.Save(classItemSaveDetails, Operation.Add);
        }

        [HttpPut]
        [Route("{classItemId}")]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public dynamic Update(int classItemId, ClassItemSaveDetails classItemSaveDetails)
        {
            return _classItemPicklistMaintenance.Save(classItemSaveDetails, Operation.Update);
        }

        [HttpDelete]
        [Route("{classItemId}")]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public dynamic Delete(int classItemId, bool confirm)
        {
            return _classItemPicklistMaintenance.Delete(classItemId, confirm);
        }

        [HttpGet]
        [Route]
        public PagedResults ClassItems(
            string @class, string country, string propertyType, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string subClass = "", string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var all = MatchingItems(@class, subClass, country, propertyType, search);

            var classItems = all as ClassItem[] ?? all.ToArray();
            var result = Helpers.GetPagedResults(classItems,
                                           extendedQueryParams,
                                           x => x.Key.ToString(), x => null, search);

            result.Ids = Helpers.GetPagedResults(classItems, new CommonQueryParameters { SortDir = extendedQueryParams?.SortDir, SortBy = extendedQueryParams?.SortBy, Take = classItems.Length },
                                                    x => x.Key.ToString(), x => null, search).Data.Select(_ => _.Key);

            return result;
        }

        IEnumerable<ClassItem> MatchingItems(string @class, string subClass, string country, string propertyType, string search = "")
        {
            var all = _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>().AsQueryable();
            var filtered = all.Where(ci => ci.Class.CountryCode.Equals(country)
                                           && ci.Class.PropertyType.Equals(propertyType)
                                           && ci.Class.Class.Equals(@class));

            if (!string.IsNullOrEmpty(subClass))
                filtered = filtered.Where(ci => ci.Class.SubClass == subClass);

            var interim = filtered.ToArray().Select(_ => new ClassItem
            {
                Key = _.Id,
                ItemNo = _.ItemNo,
                InternalItemNo = string.IsNullOrEmpty(_.Class.SubClass) ? $"undefined({_.ItemNo})" : _.ItemNo,
                Value = _.ItemDescription,
                Class = _.Class.Class,
                SubClass = _.Class.SubClass,
                Language = _.Language != null ? _.Language.Name : string.Empty
            });

            var result = interim.ToArray();

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(_ => _.InternalItemNo.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1
                                         || _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1
                                         || !string.IsNullOrEmpty(_.SubClass) && _.SubClass.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1).ToArray();

            }

            return result.OrderBy(_ => _.SubClass).ThenBy(_ => _.ItemNo).ThenBy(_ => _.Language);
        }
    }

    public class ClassItemSaveDetails
    {
        public int Id { get; set; }
        [Required]
        public string Class { get; set; }
        public int TmClassId { get; set; }
        public string SubClass { get; set; }
        [MaxLength(20)]
        public string ItemNo { get; set; }
        [Required]
        public string ItemDescription { get; set; }
        public bool IsDefaultItem { get; set; }
        [Required]
        public string Country { get; set; }
        [Required]
        public string PropertyType { get; set; }
        public TableCodePicklistController.TableCodePicklistItem Language { get; set; }
    }

    public class ClassItem
    {
        [PicklistKey]
        [PicklistCode]
        public int Key { get; set; }

        [Required]
        [MaxLength(20)]
        public string ItemNo { get; set; }
        
        [DisplayName("ItemNumber")]
        [DisplayOrder(0)]
        public string InternalItemNo { get; set; }

        [Required]
        [DisplayName("ItemDescription")]
        [DisplayOrder(1)]
        public string Value { get; set; }

        [Required]
        [DisplayName("Language")]
        [DisplayOrder(2)]
        public string Language { get; set; }

        [DisplayName("SubClass")]
        [DisplayOrder(3)]
        public string SubClass { get; set; }

        [DisplayName("Class")]
        [DisplayOrder(4)]
        [PicklistColumn(sortable: false)]
        public string Class { get; set; }
    }
}