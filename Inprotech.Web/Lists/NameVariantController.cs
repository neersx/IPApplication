using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class NameVariantController : ApiController
    {
        readonly IDbContext _dbContext;

        public NameVariantController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [Route("api/lists/namevariant")]
        [RequiresNameAuthorization]
        public dynamic Get(int nameId)
        {
            return _dbContext.Set<NameVariant>()
                             .Where(n => n.NameId == nameId)
                             .ToArray()
                             .Select(n => new
                            {
                                         Key = n.Id,
                                         Description = FormattedName.For(n.NameVariantDesc, n.FirstNameVariant)
                            });
        }
    }
}