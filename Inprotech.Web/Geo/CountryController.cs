using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using System;
using System.Linq;
using System.Web.Http;

namespace Inprotech.Web.Geo
{
    [Authorize]
    public class CountryController : ApiController
    {
        readonly IDbContext _dbContext;

        public CountryController(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        [HttpGet]
        public dynamic List(string q)
        {
            q = q ?? string.Empty;
            var model = _dbContext.Set<Country>().ToArray()
                            .Where(c => c.Name.StartsWith(q, StringComparison.OrdinalIgnoreCase) ||
                                        c.Id.StartsWith(q, StringComparison.OrdinalIgnoreCase))
                            .Select(c => new 
                                         {
                                            Key = c.Id,
                                            c.Id,
                                            c.Name

                                         }).OrderBy(c => c.Name).ToArray();

            return model;
        }
    }
}
