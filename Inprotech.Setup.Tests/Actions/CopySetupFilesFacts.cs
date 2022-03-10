//using System.Collections.Generic;
//using Inprotech.Setup.Core.Actions;
//using NSubstitute;
//using Xunit;

//namespace Inprotech.Setup.Tests.Actions
//{
//    public class CopySetupFilesFacts
//    {
//        readonly IFileSystem _fileSystem;

//        public CopySetupFilesFacts()
//        {
//            _fileSystem = Substitute.For<Core.IFileSystem>();
//        }

//        [Fact]
//        public void ShouldNotContinueOnException()
//        {
//            Assert.False(new CopySetupFiles(_fileSystem).ContinueOnException);
//        }

//        //[Fact]
//        //public void ShouldDeleteTheEntireDirectory()
//        //{
//        //    new CopySetupFiles(_fileSystem).Run(new Dictionary<string, object> { { "InstanceDirectory", "a" } }, null);

//        //    _fileSystem.Received(1).CopyDirectory(Constants.ContentRoot, "a");
//        //}
//    }
//}

