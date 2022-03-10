using System;
using CPAXML.Extensions;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.IPPlatform.FileApp.Validators;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Validators
{
    public class FileDirectPatentCaseValidatorFacts
    {
        readonly FileCase _fileCase = new FileCase
        {
            ApplicantName = "Some Inventor",
            BibliographicalInformation = new Biblio
            {
                Title = Fixture.String(),
                PriorityDate = Fixture.Today().Iso8601OrNull(),
                PriorityNumber = Fixture.String(),
                PriorityCountry = Fixture.String(),
                FilingLanguage = Fixture.String()
            }
        };

        FileDirectPatentCaseValidator CreateSubject()
        {
            return new FileDirectPatentCaseValidator(Fixture.Today);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCaseDoesNotHaveCaseTitle()
        {
            var subject = CreateSubject();

            _fileCase.BibliographicalInformation.Title = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingTitle, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCaseDoesNotHaveFilingLanguage()
        {
            var subject = CreateSubject();

            _fileCase.BibliographicalInformation.FilingLanguage = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingFilingLanguage, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCaseDoesNotHavePriorityCountry()
        {
            var subject = CreateSubject();

            _fileCase.BibliographicalInformation.PriorityCountry = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPriorityCountry, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCaseDoesNotHavePriorityDate()
        {
            var subject = CreateSubject();

            _fileCase.BibliographicalInformation.PriorityDate = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPriorityDate, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCaseDoesNotHavePriorityNumber()
        {
            var subject = CreateSubject();

            _fileCase.BibliographicalInformation.PriorityNumber = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPriorityNo, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCaseMissingApplicantName()
        {
            var subject = CreateSubject();

            _fileCase.ApplicantName = null;

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.MissingPriorityApplicantName, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnErrorWhenBuiltDirectPatentCasePassedDeadlineDate()
        {
            var subject = CreateSubject();

            var lastYear = Fixture.Today().Subtract(TimeSpan.FromDays(366));

            _fileCase.BibliographicalInformation.PriorityDate = lastYear.ToString("yyyy-MM-dd"); /* more than 12 months */

            Assert.False(subject.TryValidate(_fileCase, out var result));
            Assert.Equal(ErrorCodes.PassedPriorityDeadline, result.ErrorCode);
        }

        [Fact]
        public void ShouldReturnValidated()
        {
            var subject = CreateSubject();

            Assert.True(subject.TryValidate(_fileCase, out _));
        }
    }
}