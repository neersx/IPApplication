using System;
using Inprotech.Contracts;
using Inprotech.Contracts.Messages.PtoAccess.CleanUp;
using Inprotech.IntegrationServer.PtoAccess.CleanUp;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.CleanUp
{
    public class FileCleanUpLoggerFacts : FactBase
    {
        [Fact]
        public void ShouldLogFileCleanedUpMessage()
        {
            var sessionGuid = Guid.NewGuid();
            var path = @"C:\inprotech\tempstorage\ptointegration\" + sessionGuid + @"\somefolder\file.txt";
            var reason = "reason";

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new FileCleanedUp(path, sessionGuid, reason));

            var expectedMessage = $"FileCleanedUp - \"{path}\" for session {sessionGuid} because reason";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage));
        }

        [Fact]
        public void ShouldLogFileCleanUpFailedMessage()
        {
            var sessionGuid = Guid.NewGuid();
            var path = @"C:\inprotech\tempstorage\ptointegration\" + sessionGuid + @"\somefolder\file.txt";
            var reason = "reason";
            var exception = new Exception("failed");

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new FileCleanUpFailed(path, sessionGuid, reason, exception));

            var expectedMessage = $"FileCleanUpFailed - \"{path}\" for session {sessionGuid} because reason, exception: failed";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage), Arg.Is(exception));
        }

        [Fact]
        public void ShouldLogFolderCleanedUpMessage()
        {
            var sessionGuid = Guid.NewGuid();
            var path = @"C:\inprotech\tempstorage\ptointegration\" + sessionGuid + @"\somefolder\file.txt";
            var reason = "reason";

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new FolderCleanedUp(path, sessionGuid, reason));

            var expectedMessage = $"FolderCleanedUp - \"{path}\" for session {sessionGuid} because reason";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage));
        }

        [Fact]
        public void ShouldLogFolderCleanUpFailedMessage()
        {
            var sessionGuid = Guid.NewGuid();
            var path = @"C:\inprotech\tempstorage\ptointegration\" + sessionGuid + @"\somefolder\file.txt";
            var reason = "reason";
            var exception = new Exception("failed");

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new FolderCleanUpFailed(path, sessionGuid, reason, exception));

            var expectedMessage = $"FolderCleanUpFailed - \"{path}\" for session {sessionGuid} because reason, exception: failed";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage), Arg.Is(exception));
        }

        [Fact]
        public void ShouldLogLegacyFileCleanedUpMessage()
        {
            var path = @"C:\inprotech\tempstorage\ptointegration\somefolder\file.txt";
            var reason = "reason";

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new LegacyFileCleanedUp(path, reason));

            var expectedMessage = $"LegacyFileCleanedUp - \"{path}\" because reason";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage));
        }

        [Fact]
        public void ShouldLogLegacyFileCleanUpFailedMessage()
        {
            var sessionGuid = Guid.NewGuid();
            var path = @"C:\inprotech\tempstorage\ptointegration\" + sessionGuid + @"\somefolder\file.txt";
            var reason = "reason";
            var exception = new Exception("failed");

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new LegacyFileCleanUpFailed(path, reason, exception));

            var expectedMessage = $"LegacyFileCleanUpFailed - \"{path}\" because reason, exception: failed";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage), Arg.Is(exception));
        }

        [Fact]
        public void ShouldLogLegacyFolderCleanedUpMessage()
        {
            var path = @"C:\inprotech\tempstorage\ptointegration\somefolder\file.txt";
            var reason = "reason";

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new LegacyFolderCleanedUp(path, reason));

            var expectedMessage = $"LegacyFolderCleanedUp - \"{path}\" because reason";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage));
        }

        [Fact]
        public void ShouldLogLegacyFolderCleanUpFailedMessage()
        {
            var sessionGuid = Guid.NewGuid();
            var path = @"C:\inprotech\tempstorage\ptointegration\" + sessionGuid + @"\somefolder\file.txt";
            var reason = "reason";
            var exception = new Exception("failed");

            var fixture = new FileCleanUpLoggerFixture();

            fixture.Subject.Handle(new LegacyFolderCleanUpFailed(path, reason, exception));

            var expectedMessage = $"LegacyFolderCleanUpFailed - \"{path}\" because reason, exception: failed";
            fixture.Logger.Received(1).Information(Arg.Is(expectedMessage), Arg.Is(exception));
        }
    }

    internal class FileCleanUpLoggerFixture : IFixture<FileCleanUpLogger>
    {
        public IBackgroundProcessLogger<FileCleanUpLogger> Logger = Substitute.For<IBackgroundProcessLogger<FileCleanUpLogger>>();

        public FileCleanUpLogger Subject => new FileCleanUpLogger(Logger);
    }
}