using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.DebtorOnly
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DebtorOnlyBillDebtorSelection : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void PickLocalDebtorWithCopiesToWhenCreating()
        {
            var data = new DebtorOnlyBillDataSetup().Setup();

            var debtorData = BillingService.GetDebtor(data.LocalDebtor.Id,
                                                      null, null, null, false,
                                                      data.StaffName.Id, data.EntityId, null, DateTime.Today);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.LocalDebtor.Id,
                                                AddressId = data.LocalDebtor.PostalAddressId,
                                                IsMultiCaseAllowed = false,
                                                BilledAmount = 0,
                                                BillPercentage = 100,
                                                TotalWip = data.DebtorOnlyWipLocalDebtor.Balance + data.DebtorOnlyWipDiscountLocalDebtor.Balance,
                                                Discounts = new List<DebtorDiscount>
                                                {
                                                    new()
                                                    {
                                                        NameId = data.LocalDebtor.Id,
                                                        Sequence = 0,
                                                        DiscountRate = (decimal) 10.0,
                                                        ApplyAs = "Discount",
                                                        BasedOnAmount = false
                                                    }
                                                },
                                                CopiesTos = new List<DebtorCopiesTo>
                                                {
                                                    new()
                                                    {
                                                        /*
                                                         * For Debtor Only Bills just being created,
                                                         * Copies To is derived from the Associated Name of the debtor with a 'Copy Bills To' relationship.
                                                         */
                                                        DebtorNameId = data.LocalDebtor.Id,
                                                        CopyToNameId = data.CopyBillsTo.Id,
                                                        CopyToName = data.CopyBillsTo.Formatted(NameStyles.FirstNameThenFamilyName),
                                                        AddressId = data.CopyBillsTo.PostalAddressId,
                                                        ContactNameId = data.CopyBillsToContact.Id,
                                                        ContactName = data.CopyBillsToContact.Formatted(NameStyles.FirstNameThenFamilyName)
                                                    }
                                                }
                                            },
                                            debtorData, "Local Debtor");
        }

        [Test]
        public void PickForeignDebtorWithCopiesToWhenCreating()
        {
            var data = new DebtorOnlyBillDataSetup().Setup();

            var debtorData = BillingService.GetDebtor(data.ForeignDebtor.Id,
                                                      null, null, null, false,
                                                      data.StaffName.Id, data.EntityId, null, DateTime.Today);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.ForeignDebtor.Id,
                                                AddressId = data.ForeignDebtor.PostalAddressId,
                                                IsMultiCaseAllowed = false,
                                                BilledAmount = 0,
                                                BillPercentage = 100,
                                                TotalWip = data.DebtorOnlyWipForeignDebtor.Balance + data.DebtorOnlyWipDiscountForeignDebtor.Balance,
                                                BuyExchangeRate = (decimal) 1.1,
                                                SellExchangeRate = (decimal) 1.1,
                                                Currency = "F1",
                                                Discounts = new List<DebtorDiscount>
                                                {
                                                    new()
                                                    {
                                                        NameId = data.ForeignDebtor.Id,
                                                        Sequence = 0,
                                                        DiscountRate = (decimal) 20.0,
                                                        ApplyAs = "Discount",
                                                        BasedOnAmount = false
                                                    }
                                                },
                                                CopiesTos = new List<DebtorCopiesTo>
                                                {
                                                    /*
                                                     * For Debtor Only Bills just being created,
                                                     * Copies To is derived from the Associated Name of the debtor with a 'Copy Bills To' relationship.
                                                     */
                                                    new()
                                                    {
                                                        DebtorNameId = data.ForeignDebtor.Id,
                                                        CopyToNameId = data.CopyBillsTo.Id,
                                                        CopyToName = data.CopyBillsTo.Formatted(NameStyles.FirstNameThenFamilyName),
                                                        AddressId = data.CopyBillsTo.PostalAddressId,
                                                        ContactNameId = data.CopyBillsToContact.Id,
                                                        ContactName = data.CopyBillsToContact.Formatted(NameStyles.FirstNameThenFamilyName)
                                                    }
                                                }
                                            },
                                            debtorData, "Foreign Debtor");
        }

        [Test]
        public void LoadExistingLocalDebtorBill()
        {
            var data = DbSetup.Do(x =>
            {
                var interim = new DebtorOnlyBillDataSetup().Setup(x.DbContext);

                var openItem = new OpenItemBuilder(x.DbContext)
                               {
                                   StaffId = interim.StaffName.Id,
                                   StaffProfitCentre = interim.StaffProfitCentre.Id,
                                   EntityId = interim.EntityId,
                                   LocalValue = interim.DebtorOnlyWipLocalDebtor.LocalValue,
                                   LocalBalance = interim.DebtorOnlyWipLocalDebtor.Balance.GetValueOrDefault()
                               }
                               .BuildDebtorOnlyDraftBill(interim.LocalDebtor.Id, interim.DebtorOnlyWipLocalDebtor)
                               .Single();

                var copiesTo = new NameBuilder(x.DbContext).CreateClientOrg("cc-org");
                var copiesToContact = new NameBuilder(x.DbContext).CreateClientIndividual("cc-contact");

                var snapshot = x.InsertWithNewId(new NameAddressSnapshot
                {
                    NameId = copiesTo.Id,
                    FormattedName = copiesTo.Formatted(),
                    FormattedAddress = copiesTo.PostalAddress().FormattedOrNull(),
                    AttentionNameId = copiesToContact.Id,
                    AddressCode = copiesTo.PostalAddressId
                }, _ => _.NameSnapshotId);

                x.Insert(new OpenItemCopyTo
                {
                    ItemEntityId = openItem.ItemEntityId,
                    ItemTransactionId = openItem.ItemTransactionId,
                    AccountEntityId = openItem.AccountEntityId,
                    AccountDebtorId = interim.LocalDebtor.Id,
                    NameSnapshotId = snapshot.NameSnapshotId
                });

                return new
                {
                    DebtorId = interim.LocalDebtor.Id,
                    DebtorAddressId = interim.LocalDebtor.PostalAddressId,
                    RaisedByStaffId = interim.StaffName.Id,
                    TotalWip = interim.DebtorOnlyWipLocalDebtor.LocalValue + interim.DebtorOnlyWipDiscountLocalDebtor.LocalValue,
                    NameSnapshot = snapshot,
                    OpenItem = openItem
                };
            });

            var debtors = BillingService.GetDebtorList(data.OpenItem.ItemEntityId, data.OpenItem.ItemTransactionId, data.RaisedByStaffId, null);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId,
                                                AddressId = data.DebtorAddressId,
                                                OpenItemNo = data.OpenItem.OpenItemNo,
                                                TotalWip = data.TotalWip,
                                                BillPercentage = 100,
                                                BilledAmount = 0,
                                                IsMultiCaseAllowed = false,
                                                CopiesTos = new List<DebtorCopiesTo>
                                                {
                                                    /*
                                                     * Copy To can still derive from Associated Names with a 'Copy Bills To' relationship.
                                                     * However in this instance, this is an overriden copies to which is saved into OPENITEMCOPYTO
                                                     */
                                                    new()
                                                    {
                                                        DebtorNameId = data.DebtorId,
                                                        Address = data.NameSnapshot.FormattedAddress,
                                                        AddressId = data.NameSnapshot.AddressCode,
                                                        ContactNameId = data.NameSnapshot.AttentionNameId,
                                                        ContactName = data.NameSnapshot.FormattedAttention,
                                                        CopyToName = data.NameSnapshot.FormattedName,
                                                        CopyToNameId = data.NameSnapshot.NameId.GetValueOrDefault()
                                                    }
                                                }
                                            },
                                            debtors.DebtorList.Single());
        }
    }
}