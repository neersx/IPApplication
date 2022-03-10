using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/Tasks")]
    public class TaskPicklistController : ApiController
    {
        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "TaskName",
                SortDir = "asc"
            });

        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public TaskPicklistController(IPreferredCultureResolver preferredCultureResolver, IDbContext dbContext, Func<DateTime> clock)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _clock = clock;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(TaskList))]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var queryParams = SortByParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();
            var task = from t in _dbContext.Set<SecurityTask>()
                       join p in _dbContext.ValidObjects("TASK", _clock().Date) on t.Id.ToString() equals p.ObjectIntegerKey
                       join pr in _dbContext.PermissionRule("TASK", null, null) on t.Id equals pr.ObjectIntegerKey into permission
                       from prItems in permission.DefaultIfEmpty()
                       select new
                       {
                           TaskKey = p.ObjectIntegerKey,
                           TaskName = DbFuncs.GetTranslation(t.Name, null, t.TaskNameTId, culture),
                           Description = DbFuncs.GetTranslation(t.Description, null, t.DescriptionTId, culture),
                           p.InternalUse,
                           p.ExternalUse,
                           ExecutePermission = prItems.ExecutePermission == 1,
                           InsertPermission = prItems.InsertPermission == 1,
                           UpdatePermission = prItems.UpdatePermission == 1,
                           DeletePermission = prItems.DeletePermission == 1
                       };

            if (!string.IsNullOrEmpty(search))
            {
                task = task.Where(_ => _.TaskName.Contains(search) || _.Description.Contains(search));
            }

            return Helpers.GetPagedResults(task.Select(p => new TaskList
            {
                Key = p.TaskKey,
                TaskName = p.TaskName,
                Description = p.Description,
                InternalUse = p.InternalUse,
                ExternalUse = p.ExternalUse,
                ExecutePermission = p.ExecutePermission,
                InsertPermission = p.InsertPermission,
                UpdatePermission = p.UpdatePermission,
                DeletePermission = p.DeletePermission
            }), queryParams, null, null, null);
        }
    }
}

public class TaskList
{
    [PicklistKey]
    public string Key { get; set; }
    [PicklistDescription]
    public string TaskName { get; set; }
    public string Description { get; set; }
    public bool? InternalUse { get; set; }
    public bool? ExternalUse { get; set; }
    public bool ExecutePermission { get; set; }
    public bool InsertPermission { get; set; }
    public bool UpdatePermission { get; set; }
    public bool DeletePermission { get; set; }
}
