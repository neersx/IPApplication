using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CPAXML.Extensions;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class ComparisonDocumentsProviderFacts
    {
        public ComparisonDocumentsProviderFacts()
        {
            _subject = new ComparisonDocumentsProvider(_biblio);
        }

        readonly IBiblioStorage _biblio = Substitute.For<IBiblioStorage>();
        readonly ComparisonDocumentsProvider _subject;

        [Fact]
        public async Task DocumentsReturnedWithDetails()
        {
            var wrapper = new ImageFileWrapper
            {
                FileName = "CDE",
                ObjectId = "ABC",
                DocDesc = "Non-Final Rejection",
                MailDate = Fixture.PastDate().Iso8601OrNull(),
                DocCode = Fixture.String(),
                PageCount = Fixture.Integer(),
                DocCategory = Fixture.String()
            };

            _biblio.Read(Arg.Any<ApplicationDownload>())
                 .Returns(new BiblioFile()
                 {
                     ImageFileWrappers = new List<ImageFileWrapper>() { wrapper }
                 });

            var application = new ApplicationDownload
            {
                Number = Fixture.String()
            };

            var r = (await _subject.For(application, new Document[0])).Single();

            var ifw = wrapper.ToAvailableDocument();
            Assert.Equal(ifw.FileNameObjectId, r.DocumentObjectId);
            Assert.Equal(ifw.MailRoomDate, r.MailRoomDate);
            Assert.Equal(ifw.DocumentDescription, r.DocumentDescription);
            Assert.Equal(ifw.DocumentCategory, r.DocumentCategory);
            Assert.Equal(ifw.PageCount, r.PageCount);
            Assert.Equal(ifw.FileWrapperDocumentCode, r.FileWrapperDocumentCode);
            Assert.Equal(application.Number, r.ApplicationNumber);
        }

        [Fact]
        public async Task ReturnDocumentsNotYetDownloadedInDescendingOrder()
        {
            var doc = new Document
            {
                DocumentObjectId = "ABC",
                DocumentDescription = "Non-Final Rejection",
                MailRoomDate = Fixture.Today()
            };

            _biblio.Read(Arg.Any<ApplicationDownload>())
                 .Returns(new BiblioFile()
                 {
                     ImageFileWrappers = new List<ImageFileWrapper>()
                       {
                           new ImageFileWrapper(){FileName = "CDE",DocDesc = "Non-Final Rejection",MailDate = Fixture.PastDate().Iso8601OrNull()},
                           new ImageFileWrapper(){FileName = "ABC",DocDesc = "Non-Final Rejection",MailDate = Fixture.Today().Iso8601OrNull()}
                       }
                 });

            var r = (await _subject.For(new ApplicationDownload(), new[] { doc })).ToArray();

            Assert.Equal("ABC", r.First().DocumentObjectId);
            Assert.Equal("CDE", r.Last().DocumentObjectId);
            Assert.Equal(2, r.Count());
        }
    }
}