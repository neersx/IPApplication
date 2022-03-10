using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Keywords;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{
    class QuickSearchDbSetup : DbSetup
    {
        public QuickSearchDbSetupResult Setup()
        {
            var country = DbContext.Set<Country>().First(c => c.Id == "AU");
            var country2 = DbContext.Set<Country>().First(c => c.Id == "AD");
            var caseType = DbContext.Set<CaseType>().Single(x => x.Code == "A");
            var propertyType = DbContext.Set<PropertyType>().Single(x => x.Code == "P");
            var nameType = DbContext.Set<NameType>().First();
            var name = DbContext.Set<Name>().First();
            var numberType = DbContext.Set<NumberType>().First();

            //

            var family = Insert(new Family("qsrchFamily", "some title"));

            //

            var byIrn = InsertWithNewId(new Case("qsrchIrn", country2, caseType, propertyType));

            var byTitle = InsertWithNewId(new Case("whatever1", country, caseType, propertyType)
                                                   {
                                                       Title = "qsrchTitle"
                                                   });

            var byFamily = InsertWithNewId(new Case("whatever2", country, caseType, propertyType)
                                                    {
                                                        Family = family
                                                    });

            var byStem = InsertWithNewId(new Case("whatever3", country, caseType, propertyType)
                                                  {
                                                      Stem = "qsrch"
                                                  });

            var byName = InsertWithNewId(new Case("whatever4", country, caseType, propertyType));
            Insert(new CaseName(byName, nameType, name, 0) {Reference = "qsrchRef"});

            var byNumber = InsertWithNewId(new Case("whatever5", country, caseType, propertyType));
            Insert(new OfficialNumber(numberType, byNumber, "qsrchNumber"));

            var byKeyword = InsertWithNewId(new Case("whatever6", country, caseType, propertyType));
            var kwd = InsertWithNewId(new Keyword { KeyWord = "qsrchKwd" });
            Insert(new CaseWord { KeywordNo = kwd.KeywordNo, CaseId = byKeyword.Id });

            return new QuickSearchDbSetupResult
                       {
                           SearchBy = "qsrch",
                           Irns = new List<string>
                                      {
                                          byIrn.Irn,
                                          byTitle.Irn,
                                          byFamily.Irn,
                                          byStem.Irn,
                                          byName.Irn,
                                          byNumber.Irn,
                                          byKeyword.Irn
                                      }
                       };
        }

        public QuickSearchDbSetupResult SetupSingleResult()
        {
            var country = DbContext.Set<Country>().First();
            var caseType = DbContext.Set<CaseType>().Single(x => x.Code == "A");
            var propertyType = DbContext.Set<PropertyType>().Single(x => x.Code == "P");
            //

            var byIrn = InsertWithNewId(new Case("qsrchIrn", country, caseType, propertyType));

            return new QuickSearchDbSetupResult
            {
                SearchBy = "qsrch",
                Irns = new List<string>
                {
                    byIrn.Irn
                }
            };
        }
    }

    class QuickSearchDbSetupResult
    {
        public string SearchBy { get; set; }
        public List<string> Irns { get; set; }
    }
}
