using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Filing
{
    public interface IFilingLanguageResolver
    {
        string Resolve(string caseReference);
    }

    public class FilingLanguageResolver : IFilingLanguageResolver
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly ISiteControlReader _siteControlReader;

        public FilingLanguageResolver(IDbContext dbContext, ISiteControlReader siteControlReader, IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _docItemRunner = docItemRunner;
        }

        public string Resolve(string caseReference)
        {
            var docItemName = _siteControlReader.Read<string>(SiteControls.FilingLanguage);

            if (string.IsNullOrWhiteSpace(docItemName))
            {
                return null;
            }

            var docitem = _dbContext.Set<DocItem>().SingleOrDefault(_ => _.Name == docItemName);
            if (docitem == null)
            {
                return null;
            }

            return _docItemRunner.Run(docitem.Id, new Dictionary<string, object> {{"gstrEntryPoint", caseReference}})
                                 .ScalarValue<string>();
        }
    }
}