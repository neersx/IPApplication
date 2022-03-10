using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("STATUS")]
    public class Status
    {
        [Obsolete("For persistence only.")]
        public Status()
        {
        }

        public Status(Int16 id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Status is required.");

            Name = name;
            Id = id;
        }

        [Key]
        [Column("STATUSCODE")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; internal set; }

        [Column("INTERNALDESC")]
        [Required]
        [MaxLength(50)]
        public string Name { get; set; }
        
        [Column("EXTERNALDESC")]
        [MaxLength(50)]
        public string ExternalName { get; set; }

        [Column("INTERNALDESC_TID")]
        public int? NameTId { get; set; }

        [Column("EXTERNALDESC_TID")]
        public int? ExternalNameTId { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("LIVEFLAG")]
        public decimal? LiveFlag { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("REGISTEREDFLAG")]
        public decimal? RegisteredFlag { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("RENEWALFLAG")]
        public decimal? RenewalFlag { get; set; }

        [Column("POLICERENEWALS")]
        public decimal? PoliceRenewals { get; set; }

        [Column("POLICEEXAM")]
        public decimal? PoliceExam { get; set; }

        [Column("POLICEOTHERACTIONS")]
        public decimal? PoliceOtherActions { get; set; }

        [Column("LETTERSALLOWED")]
        public decimal? LettersAllowed { get; set; }

        [Column("CHARGESALLOWED")]
        public decimal? ChargesAllowed { get; set; }

        [Column("REMINDERSALLOWED")]
        public decimal? RemindersAllowed { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("CONFIRMATIONREQ")]
        public decimal ConfirmationRequiredFlag { get; set; }

        [MaxLength(1)]
        [Column("STOPPAYREASON")]
        public string StopPayReason { get;  set; }

        [Column("PREVENTWIP")]
        public bool? PreventWip { get; set; }

        [Column("PREVENTBILLING")]
        public bool? PreventBilling { get; set; }

        [Column("PREVENTPREPAYMENT")]
        public bool? PreventPrepayment { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("PRIORARTFLAG")]
        public bool? PriorArtFlag { get; set; }

        public bool IsConfirmationRequired => ConfirmationRequiredFlag == 1;

        public bool IsLive => LiveFlag == 1;

        public bool IsRegistered => RegisteredFlag == 1;

        public bool IsRenewal => RenewalFlag == 1;

        public override string ToString()
        {
            return Name;
        }
    }
}