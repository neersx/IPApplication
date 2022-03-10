using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component
{
    public class DmsDocumentsFacts
    {
        [Fact]
        public async Task ShouldFetchRequestedDocuments()
        {
            var searchPath = Fixture.String();

            var doc1 = new DmsDocument();
            var doc2 = new DmsDocument();

            var dms = Substitute.For<IDmsService>();
            dms.GetDocuments(searchPath, FolderType.NotSet).Returns(new DmsDocumentCollection { DmsDocuments = new List<DmsDocument> { doc1, doc2 }, TotalCount = 2 });

            var configuredDms = Substitute.For<IConfiguredDms>();
            configuredDms.GetService().Returns(dms);

            var subject = new DmsDocuments(configuredDms);
            var r = (await subject.Fetch(searchPath, FolderType.NotSet, null)).DmsDocuments.ToArray();
            var totalCount = (await subject.Fetch(searchPath, FolderType.NotSet, null)).TotalCount;

            Assert.Contains(doc1, r);
            Assert.Contains(doc2, r);
            Assert.Equal(totalCount, 2);
        }

        [Fact]
        public async Task ShouldFetchRequestedRelatedDocument()
        {
            var searchPath = Fixture.String();

            var doc1 = new DmsDocument();
            var doc2 = new DmsDocument();

            var dms = Substitute.For<IDmsService>();
            dms.GetDocuments(searchPath, FolderType.NotSet).Returns(new DmsDocumentCollection { DmsDocuments = new List<DmsDocument> { doc1, doc2 }, TotalCount = 2 });

            var configuredDms = Substitute.For<IConfiguredDms>();
            configuredDms.GetService().Returns(dms);

            var subject = new DmsDocuments(configuredDms);
            var r = (await subject.Fetch(searchPath, FolderType.NotSet, null)).DmsDocuments.ToArray();
            var totalCount = (await subject.Fetch(searchPath, FolderType.NotSet, null)).TotalCount;

            Assert.Contains(doc1, r);
            Assert.Contains(doc2, r);
            Assert.Equal(totalCount, 2);
        }
    }
}