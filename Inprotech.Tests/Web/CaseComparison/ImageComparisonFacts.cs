using System.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseComparison;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseComparison
{
    public class ImageComparisonFacts : FactBase
    {
        [Fact]
        public void ShouldReturnEncryptedImageIdsForComparison()
        {
            int caseId = 1, notificationId = 1;
            var crypto = Substitute.For<ICryptoService>();
            var service = new CaseImageComparison(Db, Db, crypto);

            var caseImage = new CaseImage
            {
                CaseId = caseId,
                ImageId = 1
            }.In(Db);

            new CaseNotification
            {
                Id = notificationId,
                CaseId = caseId
            }.In(Db);

            var markImage = new CaseFiles
            {
                Type = (int) CaseFileType.MarkImage,
                FileStoreId = 2,
                CaseId = caseId
            }.In(Db);

            var thumbnail = new CaseFiles
            {
                Type = (int) CaseFileType.MarkThumbnailImage,
                FileStoreId = 3,
                CaseId = caseId
            }.In(Db);

            //encryption mapping
            crypto.Encrypt(caseImage.ImageId.ToString()).Returns("a");
            crypto.Encrypt(markImage.FileStoreId.ToString()).Returns("b");
            crypto.Encrypt(thumbnail.FileStoreId.ToString()).Returns("c");

            var r = service.Compare(caseId, notificationId);

            Assert.Equal("a", r.CaseImageIds.Single());
            Assert.Equal("b", r.DownloadedImageId);
            Assert.Equal("c", r.DownloadedThumbnailId);
        }
    }
}