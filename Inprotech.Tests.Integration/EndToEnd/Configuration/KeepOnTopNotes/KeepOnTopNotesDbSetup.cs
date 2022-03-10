using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.KeepOnTopNotes
{
    class KeepOnTopNotesDbSetup : DbSetup
    {
        public void SetupCaseTextType()
        {
            var tt1 = InsertWithNewId(new TextType(Fixture.String(5)));
            var tt2 = InsertWithNewId(new TextType(Fixture.String(5)));
            var tt3 = InsertWithNewId(new TextType(Fixture.String(5)));

            var kot1 = InsertWithNewId(new InprotechKaizen.Model.Configuration.KeepOnTopNotes.KeepOnTopTextType { TextTypeId = tt1.Id, TextType = tt1, CaseProgram = true, NameProgram = true, IsPending = true, IsRegistered = true, Type = KnownKotTypes.Case, BackgroundColor = "#00FF00" });
            var kot2 = InsertWithNewId(new InprotechKaizen.Model.Configuration.KeepOnTopNotes.KeepOnTopTextType { TextTypeId = tt2.Id, TextType = tt2, CaseProgram = true, TimeProgram = true, BillingProgram = true, TaskPlannerProgram = true, IsPending = true, Type = KnownKotTypes.Case });
            var kot3 = InsertWithNewId(new InprotechKaizen.Model.Configuration.KeepOnTopNotes.KeepOnTopTextType { TextTypeId = tt3.Id, TextType = tt3, TimeProgram = true, BillingProgram = true, IsPending = true, IsRegistered = true, Type = KnownKotTypes.Name, BackgroundColor = "#FFFFFF" });

            var caseType1 = InsertWithNewId(new CaseType { Name = Fixture.String(5) }, x => x.Code, useAlphaNumeric: true);
            var caseType2 = InsertWithNewId(new CaseType { Name = Fixture.String(5) }, x => x.Code, useAlphaNumeric: true);

            var nameType1 = InsertWithNewId(new NameType { Name = Fixture.String(10)});
            var nameType2 = InsertWithNewId(new NameType { Name = Fixture.String(10)});

            var role1 = InsertWithNewId(new Role(Fixture.Integer()) { RoleName = Fixture.String(5) });
            var role2 = InsertWithNewId(new Role(Fixture.Integer()) { RoleName = Fixture.String(5) });

            Insert(new KeepOnTopCaseType { CaseType = caseType1, KotTextType = kot1 });
            Insert(new KeepOnTopCaseType { CaseType = caseType2, KotTextType = kot1 });
            Insert(new KeepOnTopCaseType { CaseType = caseType1, KotTextType = kot2 });

            Insert(new KeepOnTopNameType { NameType = nameType1, KotTextType = kot3 });
            Insert(new KeepOnTopNameType { NameType = nameType2, KotTextType = kot3 });

            Insert(new KeepOnTopRole { Role = role1, KotTextType = kot1 });
            Insert(new KeepOnTopRole { Role = role2, KotTextType = kot1 });
        }

        public dynamic SetNewValues()
        {
            var tt1 = InsertWithNewId(new TextType(Fixture.String(5)));
            var tt2 = InsertWithNewId(new TextType(Fixture.String(5)){UsedByFlag = 1});
            var tt3 = InsertWithNewId(new TextType(Fixture.String(5)));

            return new
            {
                tt1,
                tt2,
                tt3
            };
        }
    }
}
