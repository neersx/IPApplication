using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using System;
using System.Linq;
using System.Web.Http;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class StatesController : ApiController
    {
        readonly IDbContext _dbContext;

        public StatesController(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        [Route("api/lists/states")]
        public dynamic Get(string q, [FromUri]string country = null)
        {
            q = q ?? string.Empty;

            var results = String.IsNullOrEmpty(country) ? _dbContext.Set<State>().ToArray() :
                _dbContext.Set<State>().Where(s => s.CountryCode == country).ToArray();

            return results.Where(s => s.Name.StartsWith(q, StringComparison.OrdinalIgnoreCase) ||
                                      s.Code.StartsWith(q, StringComparison.OrdinalIgnoreCase))
                          .Select(s => new 
                          {
                              s.Code,
                              s.Name,
                              s.CountryCode,
                              CountryName = s.Country.Name
                          }).OrderBy(s => s.Name)
                          .ToArray();
        }
    }
}
