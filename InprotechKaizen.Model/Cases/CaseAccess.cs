using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("ACCOUNTCASECONTACT")]
    public class CaseAccess
    {
        [Obsolete("For persistence only.")]
        public CaseAccess()
        {
        }

        public CaseAccess(Case @case, int accountId, string nameType = null, int? nameId = null, short? nameSequence = null)
        {
            if(@case == null) throw new ArgumentNullException("case");

            CaseId = @case.Id;
            AccountId = accountId;
            AccountCaseId = @case.Id;

            if (nameType != null) NameType = nameType;
            if (nameId != null) NameId = nameId.Value;
            if (nameSequence != null) Sequence = nameSequence.Value;
        }

        [Column("ACCOUNTID")]
        public int AccountId { get; protected set; }

        [Column("ACCOUNTCASEID")]
        public int AccountCaseId { get; protected set; }

        [Column("CASEID")]
        public int CaseId { get; protected set; }

        [Required]
        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameType { get; protected set; }

        [Column("NAMENO")]
        public int NameId { get; protected set; }

        [Column("SEQUENCE")]
        public int Sequence { get; protected set; }
    }
}