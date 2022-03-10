using System;
using System.Collections.Generic;
using System.Xml.Serialization;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.Search
{
    public class CaseSearchRequestFilter : SearchRequestFilter
    {
        public IEnumerable<CaseSearchRequest> SearchRequest { get; set; }

        public DueDateFilter DueDateFilter { get; set; }
    }

    public class CaseSearchRequest
    {
        public SearchElement AnySearch { get; set; }
        
        [XmlIgnore]
        public int Id { get; set; }

        [XmlIgnore]
        public string Operator { get; set; }

        //Reference
        public SearchElement ClientReference { get; set; }
        public SearchElement CaseReference { get; set; }
        public SearchElement CaseKeys { get; set; }
        public OfficialNumberElement OfficialNumber { get; set; }
        public CaseNameReferenceElement CaseNameReference { get; set; }
        public FamilyKeyList FamilyKeyList { get; set; }
        public SearchElement FamilyKey { get; set; }
        public CaseListElement CaseList { get; set; }
        public ActionKey ActionKey { get; set; }
        public CaseNameGroupElement CaseNameGroup { get; set; }
        public AttributeGroupElement AttributeGroup { get; set; }
        public PatentTermAdjustments PatentTermAdjustments { get; set; }
        public CaseNameFromCase CaseNameFromCase { get; set; }

        public EventElement Event { get; set; }

        //Details
        public CaseTypeElement CaseTypeKey { get; set; }
        public CaseTypeElement CaseTypeKeys { get; set; }

        [XmlElement]
        public short? IncludeDraftCase { get; set; }

        public SearchElement SubTypeKey { get; set; }
        public SearchElement BasisKey { get; set; }
        public SearchElement OfficeKeys { get; set; }
        public CountryCodeElement CountryCodes { get; set; }

        public SearchElement CategoryKey { get; set; }

        public ClassesElement Classes { get; set; }

        public PropertyTypeKeys PropertyTypeKeys { get; set; }

        //text
        public SearchElement TypeOfMarkKey { get; set; }
        public TitleElement Title { get; set; }
        public SearchElement KeyWord { get; set; }
        public CaseTextGroup CaseTextGroup { get; set; }
        public NameRelationships NameRelationships { get; set; }
        public InheritedName InheritedName { get; set; }

        public StatusFlags StatusFlags { get; set; }
        public SearchElement StatusKey { get; set; }
        public SearchElement RenewalStatusKey { get; set; }

        public SearchElement FileLocationKeys { get; set; }
        public SearchElement FileLocationBayNo { get; set; }
        public SearchElement PurchaseOrderNo { get; set; }
        public SearchElement HasIncompletePolicing { get; set; }
        public SearchElement HasIncompleteNameChange { get; set; }
        public QueueFlags QueueFlags { get; set; }
        public SearchElement InstructionKey { get; set; }
        public StandingInstructions StandingInstructions { get; set; }

        public SearchElement EDEDataSourceNameNo { get; set; }
        public SearchElement EDEBatchIdentifier { get; set; }
        public SearchElement CPASentBatchNo { get; set; }

        public DesignElements DesignElements { get; set; }
        public SearchElement EntitySize { get; set; }
    }

    public class DesignElements
    {
        [XmlElement]
        public SearchElement FirmElement { get; set; }
        [XmlElement]
        public SearchElement ClientElement { get; set; }
        [XmlElement]
        public SearchElement OfficialElement { get; set; }
        [XmlElement]
        public SearchElement RegistrationNo { get; set; }
        [XmlElement]
        public SearchElement Typeface { get; set; }
        [XmlElement]
        public SearchElement ElementDescription { get; set; }
        [XmlElement]
        public SearchElement IsRenew { get; set; }
    }

    public class StandingInstructions
    {
        [XmlAttribute]
        public short IncludeInherited { get; set; }

        [XmlElement]
        public SearchElement CharacteristicFlag { get; set; }
    }

    public class FamilyKeyList
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public List<FamilyKeyItem> FamilyKey { get; set; }
    }

    public class FamilyKeyItem
    {
        [XmlText]
        public string Value { get; set; }
    }

    public class CaseTypeElement : SearchElement
    {
        [XmlAttribute]
        public short IncludeCRMCases { get; set; }
    }

    public class QueueFlags
    {
        [XmlElement]
        public SearchElement HasLettersOnQueue { get; set; }

        [XmlElement]
        public SearchElement HasChargesOnQueue { get; set; }
    }

    public class OfficialNumberElement
    {
        public OfficialNumberElement()
        {
            Number = new OfficialNumberNumber();
        }

        public OfficialNumberNumber Number { get; set; }

        [XmlAttribute]
        public short Operator { get; set; }

        [XmlAttribute]
        public short UseRelatedCase { get; set; }

        [XmlElement]
        public string TypeKey { get; set; }

        [XmlAttribute]
        public short UseCurrent { get; set; }
    }

    public class OfficialNumberNumber
    {
        [XmlText]
        public string Value { get; set; }

        [XmlAttribute]
        public short UseNumericSearch { get; set; }
    }

    public class CaseNameReferenceElement
    {
        //<CaseNameReference Operator = "2" >< TypeKey > D </ TypeKey >< ReferenceNo > 00234 </ ReferenceNo ></ CaseNameReference >
        [XmlElement]
        public string TypeKey { get; set; }

        [XmlElement]
        public string ReferenceNo { get; set; }

        [XmlAttribute]
        public short Operator { get; set; }
    }

    public class CaseListElement
    {
        //<CaseList IsPrimeCasesOnly = "1" >< CaseListKey Operator="0">3</CaseListKey></CaseList>
        public SearchElement CaseListKey { get; set; }

        [XmlAttribute]
        public short IsPrimeCasesOnly { get; set; }
    }

    public class ClassesElement : SearchElement
    {
        //<Classes Operator="2" IsLocal="1" IsInternational="1">testalan</Classes>

        [XmlAttribute]
        public short IsLocal { get; set; }

        [XmlAttribute]
        public short IsInternational { get; set; }
    }

    public class CountryCodeElement : SearchElement
    {
        [XmlAttribute]
        public short IncludeDesignations { get; set; }

        [XmlAttribute]
        public short IncludeMembers { get; set; }
    }

    public class PropertyTypeKeys
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public List<PropertyTypeKeyElement> PropertyTypeKey { get; set; }
    }

    public class PropertyTypeKeyElement
    {
        [XmlText]
        public string Value { get; set; }
    }

    public class TitleElement : SearchElement
    {
        [XmlAttribute]
        public short UseSoundsLike { get; set; }
    }

    public class CaseTextGroup
    {
        [XmlElement]
        public List<CaseText> CaseText { get; set; }
    }

    public class CaseText
    {
        [XmlElement]
        public string TypeKey { get; set; }

        [XmlElement]
        public string Text { get; set; }

        [XmlAttribute]
        public short Operator { get; set; }
    }

    public class CaseNameGroupElement
    {
        [XmlElement]
        public List<CaseNameElement> CaseName { get; set; }
    }

    public class AttributeGroupElement
    {
        [XmlAttribute]
        public short BooleanOr { get; set; }
        [XmlElement]
        public List<AttributeElement> Attribute { get; set; }
    }
    public class AttributeElement
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public string TypeKey { get; set; }

        [XmlElement]
        public string AttributeKey { get; set; }

    }

    public class PatentTermAdjustments
    {
        [XmlElement]
        public PatentTermAdjustmentCriteria IPOfficeAdjustment { get; set; }

        [XmlElement]
        public PatentTermAdjustmentCriteria CalculatedAdjustment { get; set; }

        [XmlElement]
        public PatentTermAdjustmentCriteria IPOfficeDelay { get; set; }

        [XmlElement]
        public PatentTermAdjustmentCriteria ApplicantDelay { get; set; }

        [XmlElement]
        public short? HasDiscrepancy { get; set; }
    }

    public class PatentTermAdjustmentCriteria
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public string FromDays { get; set; }
        [XmlElement]
        public string ToDays { get; set; }
    }

    public class CaseNameElement
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public string TypeKey { get; set; }

        [XmlElement]
        public NameKeysElement NameKeys { get; set; }

        [XmlElement]
        public string Name { get; set; }

        [XmlElement]
        public string NameVariantKeys { get; set; }
    }

    public class NameKeysElement
    {
        [XmlText]
        public string Value { get; set; }

        [XmlAttribute]
        public short IsCurrentUser { get; set; }

        [XmlAttribute]
        public short UseAttentionName { get; set; }
    }

    public class CaseNameFromCase
    {
        [XmlElement]
        public string CaseKey { get; set; }

        [XmlElement]
        public string NameTypeKey { get; set; }
    }
    public class NameRelationships
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public string NameTypes { get; set; }

        [XmlElement]
        public string Relationships { get; set; }
    }

    public class InheritedName
    {
        public SearchElement ParentNameKey { get; set; }
        public SearchElement NameTypeKey { get; set; }
        public SearchElement DefaultRelationshipKey { get; set; }
    }

    public class StatusFlags
    {
        short _checkDeadCaseRestriction;
        [XmlAttribute]
        public short CheckDeadCaseRestriction
        {
            get => IsDead;
            set => _checkDeadCaseRestriction = value; // getter and setter required for serialisation
        }

        [XmlElement]
        public short IsPending { get; set; }

        [XmlElement]
        public short IsRegistered { get; set; }

        [XmlElement]
        public short IsDead { get; set; }
    }

    public class EventElement
    {
        [XmlAttribute]
        public string Operator { get; set; }
        [XmlAttribute]
        public short IsRenewalsOnly { get; set; }
        [XmlAttribute]
        public short IsNonRenewalsOnly { get; set; }
        [XmlAttribute]
        public short ByDueDate { get; set; }
        [XmlAttribute]
        public short ByEventDate { get; set; }
        [XmlElement]
        public string EventKey { get; set; }
        [XmlElement]
        public string EventKeyForCompare { get; set; }
        public DateRange DateRange { get; set; }
        public Period Period { get; set; }
        public ImportanceLevel ImportanceLevel { get; set; }
        public EventNoteTypeKeys EventNoteTypeKeys { get; set; }
        public EventNoteText EventNoteText { get; set; }

    }

    public class Period
    {
        [XmlElement]
        public string Type { get; set; }
        [XmlElement]
        public string Quantity { get; set; }
    }

    public class DateRange
    {
        [XmlAttribute]
        public string Operator { get; set; }

        [XmlElement]
        public DateTime? From { get; set; }

        [XmlElement]
        public DateTime? To { get; set; }

        public bool ShouldSerializeFrom()
        {
            return From.HasValue;
        }

        public bool ShouldSerializeTo()
        {
            return To.HasValue;
        }
    }

    public class ImportanceLevel
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlElement]
        public string From { get; set; }
        [XmlElement]
        public string To { get; set; }
    }

    public class EventNoteText
    {
        [XmlText]
        public string Value { get; set; }

        [XmlAttribute]
        public short Operator { get; set; }
    }

    public class EventNoteTypeKeys
    {
        [XmlText]
        public string Value { get; set; }

        [XmlAttribute]
        public short Operator { get; set; }
    }

    public class ActionKey : SearchElement
    {
        [XmlAttribute]
        public short IsOpen { get; set; }
    }
    
}