using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.ContentManagement;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using Xunit;

namespace Inprotech.Tests.Web.ContentManagement
{
    public class ExportContentDataComparerFacts
    {
        [Fact]
        public void ComparesCollections()
        {
            var collection1 = new List<ExportContentData>
            {
                new ExportContentData { ContentId = 1, Status = ContentStatus.ReadyToDownload }
            };

            var collection2 = new List<ExportContentData>
            {
                new ExportContentData { ContentId = 1, Status = ContentStatus.ProcessedInBackground }
            };

            var difference = collection1.Except(collection2, new ExportContentDataComparer()).Any();
            Assert.True(difference);

            collection2.First().Status = ContentStatus.ReadyToDownload;
            difference = collection1.Except(collection2, new ExportContentDataComparer()).Any();
            Assert.False(difference);
        }
    }
}
