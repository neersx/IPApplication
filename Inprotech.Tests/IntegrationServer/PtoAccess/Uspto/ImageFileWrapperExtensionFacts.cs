using CPAXML.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto
{
    public class ImageFileWrapperExtensionFacts
    {
        void AssertEqual(ImageFileWrapper wrapper, AvailableDocument ifw)
        {
            Assert.Equal(wrapper.MailDateParsed, ifw.MailRoomDate);
            Assert.Equal(wrapper.DocDesc, ifw.DocumentDescription);
            Assert.Equal(wrapper.DocCategory, ifw.DocumentCategory);
            Assert.Equal(wrapper.PageCount, ifw.PageCount);
            Assert.Equal(wrapper.DocCode, ifw.FileWrapperDocumentCode);
        }

        [Fact]
        public void ConvertsImageFileToAvailableDocument()
        {
            var wrapper = new ImageFileWrapper
            {
                FileName = "CDE",
                DocDesc = "Non-Final Rejection",
                MailDate = Fixture.PastDate().Iso8601OrNull(),
                DocCode = Fixture.String(),
                PageCount = Fixture.Integer(),
                DocCategory = Fixture.String(),
                ObjectId = Fixture.String()
            };
            var ifw = wrapper.ToAvailableDocument();
            Assert.Equal(wrapper.FileName, ifw.FileNameObjectId);
            AssertEqual(wrapper, ifw);
        }

        [Fact]
        public void RemovesPDFExtensionsFromFileName()
        {
            var wrapper = new ImageFileWrapper
            {
                FileName = "CDE.abc.pdf",
                DocDesc = "Non-Final Rejection",
                MailDate = Fixture.PastDate().Iso8601OrNull(),
                DocCode = Fixture.String(),
                PageCount = Fixture.Integer(),
                DocCategory = Fixture.String(),
                ObjectId = Fixture.String()
            };
            var ifw = wrapper.ToAvailableDocument();
            Assert.Equal("CDE.abc", ifw.FileNameObjectId);
            Assert.Equal(wrapper.ObjectId, ifw.ObjectId);
            AssertEqual(wrapper, ifw);
        }

        [Fact]
        public void UsesObjectIdIfFileNameIsNull()
        {
            var wrapper = new ImageFileWrapper
            {
                DocDesc = "Non-Final Rejection",
                MailDate = Fixture.PastDate().Iso8601OrNull(),
                DocCode = Fixture.String(),
                PageCount = Fixture.Integer(),
                DocCategory = Fixture.String(),
                ObjectId = Fixture.String()
            };
            var ifw = wrapper.ToAvailableDocument();
            Assert.Equal(wrapper.ObjectId, ifw.ObjectId);
            AssertEqual(wrapper, ifw);
        }
    }
}