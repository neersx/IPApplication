using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.BillReview
{
    public class BillReviewEmailBuilderFacts
    {
        readonly int _userIdentityId = Fixture.Integer();
        readonly IEmailRecipientsProvider _emailRecipientsProvider = Substitute.For<IEmailRecipientsProvider>();
        readonly IEmailSubjectBodyResolver _emailSubjectBodyResolver = Substitute.For<IEmailSubjectBodyResolver>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        BillReviewEmailBuilder CreateSubject(Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)> billMap = null)
        {
            var logger = Substitute.For<ILogger<BillReviewEmailBuilder>>();

            var debtors = Substitute.For<IDebtorListCommands>();
            debtors.GetCopiesTo(_userIdentityId, Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool>())
                   .Returns(x =>
                   {
                       if (billMap == null)
                       {
                           return Enumerable.Empty<DebtorCopiesTo>();
                       }

                       var itemEntityId = (int)x[2];
                       var itemTransactionId = (int)x[3];

                       return billMap.Single(_ => _.Key.ItemEntityId == itemEntityId && _.Key.ItemTransactionId == itemTransactionId).Value.DebtorCopies;
                   });

            var finalisedBillResolver = Substitute.For<IFinalisedBillDetailsResolver>();
            finalisedBillResolver.Resolve(Arg.Any<BillGenerationRequest>())
                                 .Returns(x =>
                                 {
                                     if (billMap == null)
                                     {
                                         return (ItemType.DebitNote, Fixture.Today(), Fixture.Integer(), new Dictionary<int, string>(), false);
                                     }

                                     var billData = billMap[(BillGenerationRequest)x[0]];

                                     var cases = billData.CaseIds.ToDictionary(k => k, v => $"IRN for {v}");

                                     return (ItemType.DebitNote, Fixture.Today(), billData.DebtorId, cases, Fixture.Boolean());
                                 });

            _fileSystem.ReadAllBytes(Arg.Any<string>())
                       .Returns(Array.Empty<byte>());

            return new BillReviewEmailBuilder(logger, finalisedBillResolver, _emailRecipientsProvider, _emailSubjectBodyResolver, debtors, _fileSystem);
        }

        static void AddRemainingNameIds(IEnumerable<DebtorCopiesTo> debtorCopiesTos, Dictionary<int, IEnumerable<string>> emails)
        {
            foreach (var debtorCopyTo in debtorCopiesTos)
            {
                if (debtorCopyTo.ContactNameId != null && !emails.ContainsKey((int)debtorCopyTo.ContactNameId))
                    emails.Add((int)debtorCopyTo.ContactNameId, Enumerable.Empty<string>());

                if (!emails.ContainsKey(debtorCopyTo.CopyToNameId))
                    emails.Add(debtorCopyTo.CopyToNameId, Enumerable.Empty<string>());
            }
        }

        [Fact]
        public async Task ShouldNotBuildIfBillGenerationRequestsIsMissingTransactionId()
        {
            var request = new BillGenerationRequest { ItemTransactionId = null, ResultFilePath = Fixture.String() };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (Array.Empty<DebtorCopiesTo>(), Fixture.Integer(), Array.Empty<int>()) }
            });

            var r = await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request);

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldNotBuildIfBillGenerationRequestsIsMissingResultsFilePath()
        {
            var request = new BillGenerationRequest { ItemTransactionId = Fixture.Integer(), ResultFilePath = null };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (Array.Empty<DebtorCopiesTo>(), Fixture.Integer(), Array.Empty<int>()) }
            });

            var r = await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request);

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldSetDebtorEmailAddressAsMainRecipient()
        {
            var debtorId = Fixture.Integer();
            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var debtorCopies = new DebtorCopiesTo
            {
                DebtorNameId = debtorId
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (new[] { debtorCopies }, debtorId, Array.Empty<int>()) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });

            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal("accounts@clients.com", r.Email.Recipients.Single());
        }

        [Fact]
        public async Task ShouldPreferEmailAddressFromContactOfCopyToOverTheCopyTo()
        {
            var debtorId = Fixture.Integer();
            var copyToContactNameId = Fixture.Integer();
            var copyToNameId = Fixture.Integer();

            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var debtorCopies = new DebtorCopiesTo
            {
                DebtorNameId = debtorId,
                ContactNameId = copyToContactNameId,
                CopyToNameId = copyToNameId
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (new[] { debtorCopies }, debtorId, Array.Empty<int>()) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } },
                                            { copyToNameId, new[] { "accounts-copy@clients.com" } },
                                            { copyToContactNameId, new[] { "accounts-copy-contact@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });
            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal("accounts-copy-contact@clients.com", r.Email.CcRecipients.Single());
        }
        
        [Fact]
        public async Task ShouldFallbackToEmailFromCopyToWhenEmailFromContactOfCopyToIsNotFound()
        {
            var debtorId = Fixture.Integer();
            var copyToNameId = Fixture.Integer();

            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var debtorCopies = new DebtorCopiesTo
            {
                DebtorNameId = debtorId,
                CopyToNameId = copyToNameId
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (new[] { debtorCopies }, debtorId, Array.Empty<int>()) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } },
                                            { copyToNameId, new[] { "accounts-copy@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });
            
            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal("accounts-copy@clients.com", r.Email.CcRecipients.Single());
        }

        [Fact]
        public async Task ShouldUseDebtorOnlySubjectBodyIfNoCasesIncluded()
        {
            var debtorId = Fixture.Integer();
            var emailSubject = Fixture.String();
            var emailBody = Fixture.String();

            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (Array.Empty<DebtorCopiesTo>(), debtorId, Array.Empty<int>()) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });

            _emailSubjectBodyResolver.ResolveForName(debtorId).Returns((emailSubject, emailBody));

            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal(emailSubject, r.Email.Subject);
            Assert.Equal(emailBody, r.Email.Body);
        }

        [Fact]
        public async Task ShouldUseCaseSubjectBodyIfCasesIncluded()
        {
            var debtorId = Fixture.Integer();
            var caseId = Fixture.Integer();
            var emailSubject = Fixture.String();
            var emailBody = Fixture.String();

            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (Array.Empty<DebtorCopiesTo>(), debtorId, new[] { caseId }) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });

            // IRN for <case id> is how it is setup
            _emailSubjectBodyResolver.ResolveForCase($"IRN for {caseId}").Returns((emailSubject, emailBody));

            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal(emailSubject, r.Email.Subject);
            Assert.Equal(emailBody, r.Email.Body);
        }

        [Fact]
        public async Task ShouldConcatenateCaseSubjectBodyForEveryCaseIncluded()
        {
            var debtorId = Fixture.Integer();
            var caseId1 = Fixture.Integer();
            var caseId2 = Fixture.Integer();
            var emailSubjectForCaseId1 = Fixture.String();
            var emailSubjectForCaseId2 = Fixture.String();
            var emailBodyForCaseId1 = Fixture.String();
            var emailBodyForCaseId2 = Fixture.String();

            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (Array.Empty<DebtorCopiesTo>(), debtorId, new[] { caseId1, caseId2 }) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });

            // IRN for <case id> is how it is setup
            _emailSubjectBodyResolver.ResolveForCase($"IRN for {caseId1}").Returns((emailSubjectForCaseId1, emailBodyForCaseId1));

            _emailSubjectBodyResolver.ResolveForCase($"IRN for {caseId2}").Returns((emailSubjectForCaseId2, emailBodyForCaseId2));

            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal($"{emailSubjectForCaseId1}{Environment.NewLine}{emailSubjectForCaseId2}", r.Email.Subject);
            Assert.Equal($"{emailBodyForCaseId1}{Environment.NewLine}{emailBodyForCaseId2}", r.Email.Body);
        }

        [Fact]
        public async Task ShouldIncludeBillAsAttachmentForReview()
        {
            var debtorId = Fixture.Integer();

            var request = new BillGenerationRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ResultFilePath = Fixture.String()
            };

            var subject = CreateSubject(new Dictionary<BillGenerationRequest, (DebtorCopiesTo[] DebtorCopies, int DebtorId, int[] CaseIds)>
            {
                { request, (Array.Empty<DebtorCopiesTo>(), debtorId, Array.Empty<int>()) }
            });

            _emailRecipientsProvider.Provide(debtorId, Arg.Any<IEnumerable<DebtorCopiesTo>>())
                                    .Returns(x =>
                                    {
                                        var emails = new Dictionary<int, IEnumerable<string>>
                                        {
                                            { debtorId, new[] { "accounts@clients.com" } }
                                        };

                                        AddRemainingNameIds((IEnumerable<DebtorCopiesTo>)x[1], emails);

                                        return emails;
                                    });

            var content = Fixture.RandomString(1000);
            _fileSystem.ReadAllBytes(request.ResultFilePath).Returns(Convert.FromBase64String(content));

            var r = (await subject.Build(_userIdentityId, Fixture.String(), Fixture.String(), request))
                .Single();

            Assert.Equal(content, r.Email.Attachments.Single().Content);
        }
    }
}
