using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemXmlPersistenceFacts : FactBase
    {
        OpenItemXmlPersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<OpenItemXmlPersistence>>();

            return new OpenItemXmlPersistence(Db, logger);
        }

        [Theory]
        [InlineData(OpenItemXmlType.ElectronicBillMappedValueXmlOnly)]
        [InlineData(OpenItemXmlType.FullElectronicBillXml)]
        public async Task ShouldPersistsTheFirstOpenItemXmlIfValid(OpenItemXmlType openItemXmlType)
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var openItemXml = @"<BillLines>
                <BillLine BillLineNo='1'>
                    <ActivityCode>A111</ActivityCode>
                    <ExpenseCode />
                    <TaskCode>P260</TaskCode>
                    <TimeKeeperClassification>PT</TimeKeeperClassification>
                    <LineType>F</LineType>
                </BillLine>
                <BillLine BillLineNo='2'>
                    <ActivityCode>A111</ActivityCode>
                    <ExpenseCode />
                    <TaskCode>P260</TaskCode>
                    <TimeKeeperClassification>AS</TimeKeeperClassification>
                    <LineType>F</LineType>
                </BillLine>
                </BillLines>";

            var subject = CreateSubject();
            var r = await subject.Run(3, "en", new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          OpenItemXml = new[]
                                          {
                                              new OpenItemXml
                                              {
                                                  ItemEntityId = itemEntityId,
                                                  ItemTransactionId = itemTransactionId,
                                                  XmlType = (byte)openItemXmlType,
                                                  ItemXml = openItemXml
                                              }
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var openItemXmlEntity = Db.Set<InprotechKaizen.Model.Accounting.OpenItem.OpenItemXml>().Single();

            Assert.Equal(itemEntityId, openItemXmlEntity.ItemEntityId);
            Assert.Equal(itemTransactionId, openItemXmlEntity.ItemTransactionId);
            Assert.Equal(openItemXmlType, openItemXmlEntity.XmlType);
            Assert.Equal(openItemXml, openItemXmlEntity.OpenItemXmlValue);
        }

        [Theory]
        [InlineData(OpenItemXmlType.ElectronicBillMappedValueXmlOnly)]
        [InlineData(OpenItemXmlType.FullElectronicBillXml)]
        public async Task ShouldNotPersistIfOpenItemXmlIsInvalid(OpenItemXmlType openItemXmlType)
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var openItemXml = @"<asdsf>";

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();
            var r = await subject.Run(3, "en", new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          OpenItemXml = new[]
                                          {
                                              new OpenItemXml
                                              {
                                                  ItemEntityId = itemEntityId,
                                                  ItemTransactionId = itemTransactionId,
                                                  XmlType = (byte)openItemXmlType,
                                                  ItemXml = openItemXml
                                              }
                                          }
                                      },
                                      result);

            Assert.False(r);
            Assert.Empty(Db.Set<InprotechKaizen.Model.Accounting.OpenItem.OpenItemXml>());

            Assert.Equal(KnownErrors.EBillingXmlInvalid, result.ErrorCode);
            Assert.NotNull(result.ErrorDescription);
        }
    }
}
