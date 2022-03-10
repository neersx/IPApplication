using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/eventcategories")]
    public class EventCategoryPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IEventCategoryPicklistMaintenance _eventCategoryPicklistMaintenance;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public EventCategoryPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IEventCategoryPicklistMaintenance eventCategoryPicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _eventCategoryPicklistMaintenance = eventCategoryPicklistMaintenance;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(EventCategory), ApplicationTask.MaintainEventCategory)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(EventCategory), ApplicationTask.MaintainEventCategory)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var results = Helpers.GetPagedResults(MatchingItems(search),
                                                  queryParameters,
                                                  null, x => x.Name, search);

            results.Ids = results.Data.Select(_ => _.Key).ToArray();
            return results;
        }

        IQueryable<EventCategory> MatchingItems(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            var filteredEventCategories = _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>()
                                                    .Where(_ => _.IconImage.Detail.ImageStatus != null)
                                                    .Select(_ => new
                                                                 {
                                                                     _.Id,
                                                                     Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                                     Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                                                                     _.IconImage.ImageData,
                                                                     ImageDescription = DbFuncs.GetTranslation(_.IconImage.Detail.ImageDescription, null, _.IconImage.Detail.DescriptionTId, culture),
                                                                     ImageId = _.IconImage.Id
                                                                 })
                                                    .OrderBy(_ => _.Name)
                                                    .ToArray()
                                                    .Where(_ => string.IsNullOrWhiteSpace(search) || _.Name.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0);

            return filteredEventCategories
                .Select(_ => new EventCategory(_.Id, _.Name, _.Description, _.ImageData, _.ImageDescription, _.ImageId, search))
                .AsQueryable();
        }

        [HttpGet]
        [Route("{id}")]
        public dynamic GetEventCategory(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            var data = _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>()
                                 .Where(q => q.Id == id)
                                 .Select(v => new
                                              {
                                                  Data = new
                                                         {
                                                             Key = v.Id,
                                                             v.Name,
                                                             v.Description,
                                                             ImageData = new ImageModel
                                                                         {
                                                                             Key = v.IconImage.Id,
                                                                             Description = DbFuncs.GetTranslation(v.IconImage.Detail.ImageDescription, null, v.IconImage.Detail.DescriptionTId, culture),
                                                                             Image = v.IconImage.ImageData
                                                                         }
                                                         }
                                              }).SingleOrDefault();

            if (data == null)
            {
                throw Exceptions.NotFound("No matching item found");
            }

            return data;
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainEventCategory)]
        public dynamic AddOrDuplicate(EventCategory eventCategory)
        {
            if (eventCategory == null) throw new ArgumentNullException(nameof(eventCategory));
            return _eventCategoryPicklistMaintenance.Save(eventCategory, Operation.Add);
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainEventCategory)]
        public dynamic Update(int id, EventCategory eventCategory)
        {
            if (eventCategory == null) throw new ArgumentNullException(nameof(eventCategory));
            return _eventCategoryPicklistMaintenance.Save(eventCategory, Operation.Update);
        }

        [HttpDelete]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainEventCategory)]
        public dynamic Delete(int id)
        {
            if (id <= 0) throw new ArgumentOutOfRangeException(nameof(id));
            return _eventCategoryPicklistMaintenance.Delete(id);
        }
    }

    public class EventCategory
    {
        public EventCategory()
        {
        }

        public EventCategory(short key, string name, string description, byte[] image, string imageDescription, int imageId, string search = null)
        {
            Key = key;
            Name = name;
            Description = description;
            Image = image;
            ImageDescription = imageDescription;
            ImageData = new ImageModel
                        {
                            Key = imageId,
                            Image = image,
                            Description = imageDescription
                        };
        }

        [PicklistKey]
        [PreventCopy]
        public short Key { get; set; }

        [PicklistCode]
        [DisplayName(@"Name")]
        [MaxLength(50)]
        [PicklistColumn]
        public string Name { get; set; }

        [PicklistDescription]
        [MaxLength(254)]
        [PicklistColumn]
        public string Description { get; set; }

        [DisplayName(@"Image")]
        [PicklistColumn(false)]
        public byte[] Image { get; set; }

        [DisplayName(@"ImageDescription")]
        [PicklistColumn]
        public string ImageDescription { get; set; }

        public ImageModel ImageData { get; set; }
    }
}