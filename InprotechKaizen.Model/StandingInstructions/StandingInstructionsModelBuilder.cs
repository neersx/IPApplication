using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.StandingInstructions
{
    public class StandingInstructionsModelBuilder : IModelBuilder
    {
        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            var instructionType = modelBuilder.Entity<InstructionType>();
            instructionType.Map(_ => _.ToTable("INSTRUCTIONTYPE"));
            instructionType.HasKey(_ => _.Code);
            instructionType.HasRequired(c => c.NameType)
                           .WithMany()
                           .Map(_ => _.MapKey("NAMETYPE"));
            instructionType.HasOptional(c => c.RestrictedByType)
                           .WithMany()
                           .HasForeignKey(_ => _.RestrictedByTypeCode);
            instructionType.HasMany(_ => _.Characteristics)
                           .WithRequired(_ => _.InstructionType)
                           .HasForeignKey(_ => _.InstructionTypeCode);

            var instruction = modelBuilder.Entity<Instruction>();
            instruction.Map(_ => _.ToTable("INSTRUCTIONS"));
            instruction.Property(_ => _.Id)
                       .HasColumnName("INSTRUCTIONCODE")
                       .HasDatabaseGeneratedOption(DatabaseGeneratedOption.None);

            instruction.HasKey(_ => _.Id);
            instruction.HasRequired(_ => _.InstructionType)
                       .WithMany(_ => _.Instructions)
                       .HasForeignKey(_ => _.InstructionTypeCode);

            instruction.HasMany(_ => _.Characteristics)
                       .WithRequired(c => c.Instruction)
                       .HasForeignKey(_ => _.InstructionId);
            instruction.HasMany(_ => _.CaseInstructions)
                       .WithOptional()
                       .HasForeignKey(_ => new {_.InstructionId});
            instruction.HasMany(_ => _.NameInstructions)
                       .WithOptional()
                       .HasForeignKey(_ => new {_.InstructionId});

            var characteristic = modelBuilder.Entity<Characteristic>();
            characteristic.Map(_ => _.ToTable("INSTRUCTIONLABEL"));
            characteristic.HasKey(_ => new {_.InstructionTypeCode, _.Id});
            characteristic.HasMany(_ => _.ChargeRates)
                          .WithOptional()
                          .HasForeignKey(_ => new {_.InstructionType, _.FlagNumber});
            characteristic.HasMany(c => c.ValidEvents)
                          .WithOptional(ve => ve.RequiredCharacteristic)
                          .HasForeignKey(ve => new {ve.InstructionType, ve.FlagNumber});
            characteristic.HasMany(_ => _.DataValidations)
                          .WithOptional()
                          .HasForeignKey(_ => new {_.InstructionType, _.FlagNumber});

            var selectedCharacteristic = modelBuilder.Entity<SelectedCharacteristic>();
            selectedCharacteristic.Map(_ => _.ToTable("INSTRUCTIONFLAG"));
            selectedCharacteristic.HasKey(_ => new {_.InstructionId, _.CharacteristicId});
        }
    }
}