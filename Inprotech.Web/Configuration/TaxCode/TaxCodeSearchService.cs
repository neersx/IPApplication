using System;
using System.Linq;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.TaxCode
{
    public interface ITaxCodeSearchService
    {
        IQueryable<TaxCodes> DoSearch(SearchOptions searchOptions, string culture);
    }

    public class TaxCodeSearchService : ITaxCodeSearchService
    {
        readonly IDbContext _dbContext;

        public TaxCodeSearchService(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public IQueryable<TaxCodes> DoSearch(SearchOptions searchOptions, string culture)
        {
            var taxCodes = _dbContext.Set<TaxRate>().Select(_ => new TaxCodes
            {
                Id = _.Id,
                TaxCode = _.Code,
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
            });
            if (!string.IsNullOrEmpty(searchOptions?.Text))
            {
                taxCodes = taxCodes.Where(x => x.TaxCode.Contains(searchOptions.Text) || x.Description.Contains(searchOptions.Text));
            }

            return taxCodes;
        }
    }

    public class TaxCodes
    {
        public int Id { get; set; }
        public string TaxCode { get; set; }
        public string Description { get; set; }
    }
}