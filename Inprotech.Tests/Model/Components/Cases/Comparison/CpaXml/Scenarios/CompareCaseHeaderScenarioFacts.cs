using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareCaseHeaderScenarioFacts
    {
        readonly CompareCaseHeaderScenario _subject = new CompareCaseHeaderScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("Patent", "US");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllowsAllSourceSystem()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
        }

        [Fact]
        public void ReturnsAnyTransactionMessageDetails()
        {
            var messageDetails = new[]
            {
                new TransactionMessageDetails
                {
                    TransactionMessageCode = "Validation",
                    TransactionMessageText = "Check pub number"
                },
                new TransactionMessageDetails
                {
                    TransactionMessageCode = "Validation",
                    TransactionMessageText = "Check grant date"
                },
                new TransactionMessageDetails
                {
                    TransactionMessageCode = "SomethingElse",
                    TransactionMessageText = "Some future messages"
                }
            };

            var r = _subject.Resolve(_caseDetails, messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal(new[]
                         {
                             "Check pub number", "Check grant date"
                         },
                         r.Mapped.Messages["Validation"]);

            Assert.Equal(new[]
                         {
                             "Some future messages"
                         },
                         r.Mapped.Messages["SomethingElse"]);
        }

        [Fact]
        public void ReturnsInternationalClassesFromGoodsServices()
        {
            _caseDetails.CreateGoodsServicesDetails("Nice", "027", "WEARING APPAREL, NAMELY, BLUE JEANS");
            _caseDetails.CreateGoodsServicesDetails("Nice", "025", "WEARING APPAREL, NAMELY, BLUE JEANS");
            _caseDetails.CreateGoodsServicesDetails("Not Nice", "026", "WEARING APPAREL, NAMELY, BLUE JEANS");

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal("025,027", r.ComparisonSource.IntClasses);
        }

        [Fact]
        public void ReturnsIrnFromSenderCaseReference()
        {
            _caseDetails.SenderCaseReference = "123";

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal("123", r.ComparisonSource.Ref);
        }

        [Fact]
        public void ReturnsLocalClassesFromDescriptions()
        {
            _caseDetails.CreateDescriptionDetails("Class/SubClass", "hello world");

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal("hello world", r.ComparisonSource.LocalClasses);
        }

        [Fact]
        public void ReturnsStatusDateFromEvent()
        {
            var @event = _caseDetails.CreateEventDetails("Status");
            @event.EventDate = Fixture.Today().ToString("yyyy-MM-dd");

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal(Fixture.Today(), r.ComparisonSource.StatusDate);
        }

        [Fact]
        public void ReturnsStatusFromEventText()
        {
            var @event = _caseDetails.CreateEventDetails("Status");
            @event.EventText = "the status";

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal("the status", r.ComparisonSource.Status);
        }

        [Fact]
        public void ReturnsTitleFromDescriptions()
        {
            _caseDetails.CreateDescriptionDetails("Short Title", "hello world");

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal("hello world", r.ComparisonSource.Title);
        }

        [Fact]
        public void ReturnsSenderCaseIdentifier()
        {
            var senderCaseIdentifier = Fixture.String(); 
    
            _caseDetails.SenderCaseIdentifier = senderCaseIdentifier;

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<CaseHeader>>()
                            .Single();

            Assert.Equal(senderCaseIdentifier, r.ComparisonSource.Id);
        }
    }
}