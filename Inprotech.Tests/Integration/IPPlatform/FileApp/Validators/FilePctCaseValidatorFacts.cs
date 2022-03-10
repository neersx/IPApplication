using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.IPPlatform.FileApp.Validators;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Validators
{
    public class FilePctCaseValidatorFacts
    {
        readonly FileCase _fileCase = new FileCase
        {
            ApplicantName = "Some inventor",
            BibliographicalInformation = new Biblio
            {
                ApplicationDate = Fixture.String(),
                ApplicationNumber = Fixture.String()
            }
        };

        [Fact]
        public void ShouldReturnErrorWhenBuiltPctCaseDoesNotHaveApplicantName()
        {
            var subject = new FilePctCaseValidator();

            _fileCase.ApplicantName = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPctApplicantName, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltPctCaseDoesNotHaveApplicationDate()
        {
            var subject = new FilePctCaseValidator();

            _fileCase.BibliographicalInformation.ApplicationDate = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPctIntlApplicationDate, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltPctCaseDoesNotHaveApplicationNumber()
        {
            var subject = new FilePctCaseValidator();

            _fileCase.BibliographicalInformation.ApplicationNumber = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPctIntlApplicationNo, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnValidated()
        {
            var subject = new FilePctCaseValidator();

            Assert.True(subject.TryValidate(_fileCase, out var result));
        }
    }
}