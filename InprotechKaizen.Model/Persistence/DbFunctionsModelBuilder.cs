using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Persistence
{
    public class DbFunctionsModelBuilder : IModelBuilder
    {
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PermissionsGrantedItem>().HasKey(x => x.ObjectIntegerKey);

            modelBuilder.Entity<PermissionsRuleItem>().HasKey(x => x.ObjectIntegerKey);

            modelBuilder.ComplexType<Permissions>();

            modelBuilder.ComplexType<FakePermissionsSet>();

            modelBuilder.ComplexType<PermissionsGrantedAllItem>();

            modelBuilder.ComplexType<SourceMappedEvents>();

            modelBuilder.ComplexType<EligibleCaseItem>();

            modelBuilder.ComplexType<EntryMenu>();

            modelBuilder.ComplexType<CaseDueDate>();

            modelBuilder.ComplexType<SysActiveSessions>();

            modelBuilder.ComplexType<CriteriaRows>();

            // Well-Established Security Filter Functions

            modelBuilder.Entity<FilteredRowAccessCase>()
                        .HasKey(x => x.CaseId);

            modelBuilder.Entity<FilteredRowSecurityCase>()
                        .HasKey(x => x.CaseId);

            modelBuilder.Entity<FilteredRowSecurityCaseMultiOffice>()
                        .HasKey(x => x.CaseId);

            modelBuilder.Entity<FilteredEthicalWallCase>()
                        .HasKey(x => x.CaseId);

            modelBuilder.Entity<FilteredEthicalWallName>()
                        .HasKey(x => x.NameNo);

            modelBuilder.Entity<FilteredRowSecurityName>()
                        .HasKey(x => x.NameNo);

            // Well-Established Client Access Filter Functions

            modelBuilder.Entity<FilteredUserCase>()
                        .HasKey(x => x.CaseId);

            modelBuilder.Entity<FilteredUserEvent>()
                        .HasKey(x => x.EventNo);

            modelBuilder.Entity<FilteredUserTextType>()
                        .HasKey(x => x.TextType);

            modelBuilder.Entity<FilteredUserNameTypes>()
                        .HasKey(x => x.NameType);

            modelBuilder.Entity<FilteredUserViewName>()
                        .HasKey(x => x.NameNo);

            modelBuilder.Entity<FilteredUserNumberTypes>()
                        .HasKey(x => x.NumberType);

            modelBuilder.Entity<FilteredUserAliasTypes>()
                        .HasKey(x => x.AliasType);

            modelBuilder.Entity<FilteredUserInstructionTypes>()
                        .HasKey(x => x.InstructionType);

            modelBuilder.Entity<TopicSecurity>()
                        .HasKey(x => x.TopicKey);

            modelBuilder.Entity<ValidObjectItems>()
                        .HasKey(x => x.ObjectIntegerKey);

            modelBuilder.Entity<BillRuleRow>()
                        .HasKey(x => x.RuleId);
        }
    }
}