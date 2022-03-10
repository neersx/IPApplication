using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Web.DocumentManagement;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.DocumentManagement
{
    public class DocumentManagementControllerFacts
    {
        readonly ICaseDmsFolders _dmsFolders = Substitute.For<ICaseDmsFolders>();
        readonly IDmsDocuments _dmsDocuments = Substitute.For<IDmsDocuments>();

        DocumentManagementController CreateSubject()
        {
            return new DocumentManagementController(_dmsFolders, _dmsDocuments);
        }

        [Fact]
        public void SecureByAccessDmsTaskSecurity()
        {
            var r = TaskSecurity.Secures<DocumentManagementController>(ApplicationTask.AccessDocumentsfromDms);

            Assert.True(r);
        }

        [Fact]
        public async Task ShouldCallGetDocumentsService()
        {
            var searchStringOrPath = Fixture.String();
            var qp = new CommonQueryParameters { Skip = 0, Take = 50 };
            var documents = new DmsDocumentCollection { DmsDocuments = new DmsDocument[0], TotalCount = 0 };

            _dmsDocuments.Fetch(searchStringOrPath, FolderType.NotSet, qp).Returns(documents);

            var subject = CreateSubject();

            var r = await subject.GetDocuments(searchStringOrPath, qp);

            await _dmsDocuments.Received(1).Fetch(searchStringOrPath, FolderType.NotSet, qp);

            Assert.Equal(r.Pagination.Total, documents.TotalCount);
        }

        [Fact]
        public async Task ShouldCallGetSubFolderService()
        {
            var searchStringOrPath = Fixture.String();

            var folders = new[]
            {
                new DmsFolder(), new DmsFolder()
            };

            _dmsFolders.FetchSubFolders(searchStringOrPath).Returns(folders);

            var subject = CreateSubject();

            var r = await subject.GetSubFolders(searchStringOrPath);

            await _dmsFolders.Received(1).FetchSubFolders(searchStringOrPath);

            Assert.Equal(r, folders);
        }
    }
}