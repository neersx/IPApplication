using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Cases
{
    [Table("SCREENCONTROL")]
    public class DataEntryTaskStep
    {
        [Obsolete("For persistence only...")]
        public DataEntryTaskStep()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public DataEntryTaskStep(Criteria criteria)
        {
            if (criteria == null) throw new ArgumentNullException("criteria");

            Criteria = criteria;
            CriteriaId = criteria.Id;
        }

        public DataEntryTaskStep(int criteriaId, string screenName, short screenId)
        {
            CriteriaId = criteriaId;
            ScreenName = screenName;
            ScreenId = screenId;
        }

        [Column("CRITERIANO")]
        public int CriteriaId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("SCREENNAME")]
        public string ScreenName { get; set; }

        [Column("SCREENID")]
        public short ScreenId { get; set; }

        [Column("ENTRYNUMBER")]
        public short? DataEntryTaskId { get; set; }

        [MaxLength(50)]
        [Column("SCREENTITLE")]
        public string ScreenTitle { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }

        [MaxLength(254)]
        [Column("SCREENTIP")]
        public string ScreenTip { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("MANDATORYFLAG")]
        public decimal? MandatoryFlag { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeCode { get; set; }

        [Column("NAMEGROUP")]
        [ForeignKey("NameGroup")]
        public short? NameGroupId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [MaxLength(50)]
        [Column("PROFILENAME")]
        public string ProfileName { get; set; }

        [MaxLength(254)]
        [Column("GENERICPARAMETER")]
        public string GenericParameter { get; set; }

        [MaxLength(2)]
        [Column("CREATEACTION")]
        public string CreateActionId { get; set; }

        [MaxLength(3)]
        [Column("RELATIONSHIP")]
        public string RelationshipId { get; set; }

        [Column("CHECKLISTTYPE")]
        public short? ChecklistType { get; set; }

        [MaxLength(2)]
        [Column("TEXTTYPE")]
        public string TextTypeId { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("FLAGNUMBER")]
        public int? FlagNumber { get; set; }

        [Column("SCREENTITLE_TID")]
        public int? ScreenTitleTId { get; set; }

        [Column("SCREENTIP_TID")]
        public int? ScreenTipTId { get; set; }

        public virtual Criteria Criteria { get; protected set; }

        public virtual Screen Screen { get; set; }

        public virtual NameType NameType { get; set; }

        public virtual NameGroup NameGroup { get; protected set; }

        public virtual Action CreateAction { get; set; }

        public virtual CheckList Checklist { get; set; }

        public virtual CaseRelation Relationship { get; set; }

        public virtual TextType TextType { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }

        public bool IsMandatoryStep
        {
            get { return MandatoryFlag != null && MandatoryFlag == 1m; }
        }

        public void SetNameType(NameType nameType)
        {
            NameType = nameType;
            NameTypeCode = NameType?.NameTypeCode;
        }
    }

    public static class DataEntryTaskStepExt
    {
        public static DataEntryTaskStep InheritRuleFrom(this DataEntryTaskStep dataEntryTaskStep, DataEntryTaskStep from)
        {
            if (dataEntryTaskStep == null) throw new ArgumentNullException(nameof(dataEntryTaskStep));

            dataEntryTaskStep.IsInherited = true;
            dataEntryTaskStep.CopyFrom(from);
            return dataEntryTaskStep;
        }

        static void CopyFrom(this DataEntryTaskStep dataEntryTaskStep, DataEntryTaskStep from)
        {
            dataEntryTaskStep.ScreenName = from.ScreenName;
            dataEntryTaskStep.ScreenTitle = from.ScreenTitle;
            dataEntryTaskStep.DisplaySequence = from.DisplaySequence;
            dataEntryTaskStep.ScreenTip = from.ScreenTip;
            dataEntryTaskStep.MandatoryFlag = from.MandatoryFlag;
            dataEntryTaskStep.NameTypeCode = from.NameTypeCode;
            dataEntryTaskStep.NameGroupId = from.NameGroupId;
            dataEntryTaskStep.ProfileName = from.ProfileName;
            dataEntryTaskStep.GenericParameter = from.GenericParameter;
            dataEntryTaskStep.CreateActionId = from.CreateActionId;
            dataEntryTaskStep.RelationshipId = from.RelationshipId;
            dataEntryTaskStep.ChecklistType = from.ChecklistType;
            dataEntryTaskStep.TextTypeId = from.TextTypeId;
            dataEntryTaskStep.FlagNumber = from.FlagNumber;
        }
    }
}