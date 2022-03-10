using Inprotech.Infrastructure;
using Xunit;

namespace Inprotech.Tests.Infrastructure
{
    public class UriHelperFacts
    {
        readonly IUriHelper _helper;

        public UriHelperFacts()
        {
            _helper = new UriHelper();
        }

        [Theory]
        [InlineData("www.smh.com.au", "http://www.smh.com.au/")]
        [InlineData("http://www.smh.com.au", "http://www.smh.com.au/")]
        [InlineData("https://www.smh.com.au", "https://www.smh.com.au/")]
        [InlineData("ftp://www.smh.com.au", "ftp://www.smh.com.au/")]
        [InlineData("sftp://www.smh.com.au", "sftp://www.smh.com.au/")]
        [InlineData("iwl:dms=COPERNICUS&lib=LIVE&num=6071215&ver=1&latest=1", "iwl:dms=COPERNICUS&lib=LIVE&num=6071215&ver=1&latest=1")]
        [InlineData(@"c:\inprotech-storage", "file:///c:/inprotech-storage")]
        [InlineData(@"c:\inprotech-storage\file.txt", "file:///c:/inprotech-storage/file.txt")]
        [InlineData(@"\\networklocation\c\asd", "file://networklocation/c/asd")]
        [InlineData("mailto://someone@cpaglobal.com", "mailto://someone@cpaglobal.com")]
        [InlineData("jkhkjhkjfds", "http://jkhkjhkjfds/")]
        [InlineData("asd/asd/cases?a=k", "http://asd/asd/cases?a=k")]
        public void ShouldReturnOnlyIfUriIsValid(string inputUrl, string expected)
        {
            var r = _helper.TryAbsolute(inputUrl, out var url);

            Assert.True(r);
            Assert.Equal(expected, url.ToString());
        }

        [Theory]
        [InlineData("/asd/asd/cases?a=k")]
        public void ShouldNotReturnIllegalUrls(string inputUrl)
        {
            var r = _helper.TryAbsolute(inputUrl, out var url);

            Assert.False(r);
            Assert.Null(url);
        }
    }
}