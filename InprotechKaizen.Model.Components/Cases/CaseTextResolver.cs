using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICaseTextResolver
    {
        Task<string> GetCaseText(int caseId, string textType, string classKey, int? languageCode = null);
    }

    public class CaseTextResolver : ICaseTextResolver
    {
        readonly IDbContext _dbContext;
        readonly IHtmlAsPlainText _htmlAsPlainText;

        public CaseTextResolver(IDbContext dbContext, IHtmlAsPlainText htmlAsPlainText)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _htmlAsPlainText = htmlAsPlainText ?? throw new ArgumentNullException(nameof(htmlAsPlainText));
        }

        public async Task<string> GetCaseText(int caseId, string textType, string classKey, int? languageCode = null)
        {
            if (string.IsNullOrEmpty(textType)) throw new ArgumentNullException(nameof(textType));

            var caseText = await (from ct in _dbContext.Set<CaseText>()
                                  where ct.CaseId == caseId &&
                                        ct.Class == classKey &&
                                        ct.Language == languageCode &&
                                        ct.Type == textType
                                  orderby ct.Number descending
                                  select new
                                  {
                                      Text = ct.IsLongText == 1 ? ct.LongText : ct.ShortText,
                                      ct.Number
                                  }).FirstOrDefaultAsync();

            return caseText == null ? null : _htmlAsPlainText.Retrieve(caseText.Text);
        }
    }
}
