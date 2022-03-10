using Dependable.Dispatcher;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class ErrorLoggerFacts
    {
        readonly DataDownload _dataDownload = new DataDownload();
        readonly ExceptionContext _exceptionContext = new ExceptionContext();

        public class ErrorLoggerFixture : IFixture<ErrorLogger>
        {
            public ErrorLoggerFixture()
            {
                LogEntry = Substitute.For<ILogEntry>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                DataDownloadLocationResolver.ResolveForErrorLog(Arg.Any<DataDownload>()).Returns(string.Empty);
                DataDownloadLocationResolver.ResolveForErrorLog(Arg.Any<DataDownload>(), Arg.Any<string>()).Returns(s => (string) s[1]);

                Subject = new ErrorLogger(LogEntry, DataDownloadLocationResolver);
            }

            public ILogEntry LogEntry { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public ErrorLogger Subject { get; set; }
        }

        [Fact]
        public void CreatesContextualErrorLog()
        {
            var f = new ErrorLoggerFixture();

            f.Subject.LogContextError(_exceptionContext, _dataDownload, "abc");

            f.LogEntry.Received(1).Create(_exceptionContext, Arg.Is<string>(_ => _.Contains("abc")));
        }

        [Fact]
        public void CreatesErrorLog()
        {
            var f = new ErrorLoggerFixture();

            f.Subject.Log(_exceptionContext, _dataDownload);

            f.LogEntry.Received(1).Create(_exceptionContext, Arg.Any<string>());
        }
    }
}