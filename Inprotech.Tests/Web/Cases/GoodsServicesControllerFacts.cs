using System;
using System.Threading.Tasks;
using Inprotech.Web.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class GoodsServicesControllerFacts
    {
        public class GoodsServicesTextMethod : FactBase
        {
            ICaseTextResolver CaseTextResolver { get; set; }

            GoodsServicesController CreateSubject()
            {
                CaseTextResolver = Substitute.For<ICaseTextResolver>();
                return new GoodsServicesController(CaseTextResolver);
            }

            [Fact]
            public async Task RetrievesGoodsServicesText()
            {
                var f = CreateSubject();
                var caseKey = Fixture.Integer();
                var classKey = Fixture.String();
                
                var returnData = Fixture.String();
                CaseTextResolver.GetCaseText(Fixture.Integer(), null, null).ReturnsForAnyArgs(returnData);

                var result = await f.GoodsServicesText(caseKey, classKey);
                await CaseTextResolver.Received(1).GetCaseText(caseKey, KnownTextTypes.GoodsServices, classKey);
                Assert.Equal(returnData, result);
            }

            [Fact]
            public async Task ThrowsExceptionIfClassIsNull()
            {
                var f = CreateSubject();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                                async () => await f.GoodsServicesText(Fixture.Integer(), string.Empty));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("classKey", exception.Message);
            }
        }
    }
}