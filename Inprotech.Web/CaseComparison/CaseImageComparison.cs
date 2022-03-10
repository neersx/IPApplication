using System.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Persistence;
using CaseImageComparisonResult = InprotechKaizen.Model.Components.Cases.Comparison.Results.CaseImage;

namespace Inprotech.Web.CaseComparison
{
    public interface ICaseImageComparison
    {
        CaseImageComparisonResult Compare(int caseId, int notificationId);
    }

    public class CaseImageComparison : ICaseImageComparison
    {
        readonly IDbContext _dbContext;
        readonly IRepository _repository;
        readonly ICryptoService _crypto;

        public CaseImageComparison(IDbContext dbContext, IRepository repository, ICryptoService crypto)
        {
            _dbContext = dbContext;
            _repository = repository;
            _crypto = crypto;
        }

        public CaseImageComparisonResult Compare(int caseId, int notificationId)
        {
            var caseImageIds = _dbContext.Set<InprotechKaizen.Model.Cases.CaseImage>()
                .Where(_ => _.CaseId == caseId)
                .OrderBy(_ => _.ImageSequence)
                .Select(_ => _.ImageId)
                .ToArray();

            var appCaseId = _repository.Set<CaseNotification>()
                                          .Where(cn => cn.Id == notificationId)
                                          .Select(_ => _.CaseId)
                                          .Single();

            var downloaded = _repository
                .Set<CaseFiles>()            
                .OrderByDescending(_ => _.Id)    
                .FirstOrDefault(_ => _.CaseId == appCaseId && _.Type == (int) CaseFileType.MarkImage);

            var downloadedThumbnail = _repository
                .Set<CaseFiles>()
                .OrderByDescending(_ => _.Id)
                .FirstOrDefault(_ => _.CaseId == appCaseId && _.Type == (int) CaseFileType.MarkThumbnailImage);

            if (caseImageIds.Any() == false && downloaded == null && downloadedThumbnail == null)
                return null;

            return new CaseImageComparisonResult
            {
                CaseImageIds = caseImageIds.Select(_ => _crypto.Encrypt(_.ToString())),
                DownloadedImageId = downloaded != null ? _crypto.Encrypt(downloaded.FileStoreId.ToString()) : null,
                DownloadedThumbnailId = downloadedThumbnail != null ? _crypto.Encrypt(downloadedThumbnail.FileStoreId.ToString()) : null
            };
        }
    }
}