using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases.Filing.Electronic;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewEfiling
    {
        IEnumerable<EfilingPackageListItem> GetPackages(string caseKeys);
        IEnumerable<EfilingPackageFilesListItem> GetPackageFiles(int caseKey, int exchangeId, int packageSequence);
        EfilingFileDataItem GetPackageFileData(int? caseKey, int? packageSequence, int? packageFileSequence, int? exchangeId);
        IEnumerable<EfilingHistoryDataItem> GetPackageHistory(int exchangeId);
    }

    public class CaseViewEfiling : ICaseViewEfiling
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseViewEfiling(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }
        public IEnumerable<EfilingPackageListItem> GetPackages(string caseKeys)
        {
            var culture = _preferredCultureResolver.Resolve();
            return _dbContext.GetPackages(culture, caseKeys);
        }

        public IEnumerable<EfilingPackageFilesListItem> GetPackageFiles(int caseKey, int exchangeId, int packageSequence)
        {
            return _dbContext.GetPackageFiles(caseKey, exchangeId, packageSequence);
        }

        public EfilingFileDataItem GetPackageFileData(int? caseKey, int? packageSequence, int? packageFileSequence, int? exchangeId)
        {
            return _dbContext.GetEfilingFileData(caseKey, packageSequence, packageFileSequence, exchangeId);
        }

        public IEnumerable<EfilingHistoryDataItem> GetPackageHistory(int exchangeId)
        {
            var culture = _preferredCultureResolver.Resolve();
            return _dbContext.GetPackageHistory(culture, exchangeId);
        }
    }
}