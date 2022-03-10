using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.FileLocationOffice
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/file-location-office")]
    [RequiresAccessTo(ApplicationTask.MaintainFileLocationOffice, ApplicationTaskAccessLevel.None)]
    public class FileLocationOfficeController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public FileLocationOfficeController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("")]
        public async Task<IEnumerable<FileLocationOffice>> GetFileLocationOffices(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters qp)
        {
            var queryParameters = qp ?? new CommonQueryParameters();
            var culture = _preferredCultureResolver.Resolve();
            var results = await (from t in _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)TableTypes.FileLocation)
                    join o in _dbContext.Set<InprotechKaizen.Model.Cases.FileLocationOffice>() on t.Id equals o.FileLocationId into ot
                    from o in ot.DefaultIfEmpty()
                    select new FileLocationOffice
                    {
                        Id = t.Id,
                        FileLocation = DbFuncs.GetTranslation(t.Name, null, t.NameTId, culture),
                        Office = o != null ? new Office {Key = o.OfficeId, Value = DbFuncs.GetTranslation(o.Office.Name, null, o.Office.NameTId, culture) } : null
                    }).ToArrayAsync();
            
            return results.OrderBy(_ => _.FileLocation)
                          .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                          .Skip(queryParameters.Skip.GetValueOrDefault())
                          .ToArray();
        }

        [HttpPost]
        [Route("")]
        public async Task<dynamic> UpdateFileLocationOffice(FileLocationOfficeRequest data)
        {
            if (data == null) throw new ArgumentNullException(nameof(data));
            foreach (var row in data.Rows)
            {
                var fc = await _dbContext.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().FirstOrDefaultAsync(_ => _.FileLocationId == row.Id);
                if (fc != null)
                {
                    _dbContext.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().Remove(fc);
                }
                if (row.Office != null)
                {
                    _dbContext.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().Add(new InprotechKaizen.Model.Cases.FileLocationOffice(row.Id, row.Office.Key));
                }
            }
            await _dbContext.SaveChangesAsync();
            return Ok();
        }

    }

    public class FileLocationOfficeRequest
    {
        public IEnumerable<FileLocationOffice> Rows { get; set; }
    }

    public class FileLocationOffice
    {
        public int Id { get; set; }
        public string FileLocation { get; set; }
        public Office Office { get; set; }
    }
}
