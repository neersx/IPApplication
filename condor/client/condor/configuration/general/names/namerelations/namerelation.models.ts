namespace inprotech.configuration.general.names.namerelations {
    export interface INameRelationEntity {
        id?: number;
        relationshipCode: string;
        relationshipDescription: string;
        reverseDescription: string;
        isIndividual: boolean;
        IsEmployee: boolean;
        IsOrganisation: boolean;
        IsCrmOnly?: boolean;
        HasCrmLisences: boolean;
        EthicalWall: string;
        EthicalWallValue: string;
    }

    export interface INameRelationModalOptions extends IModalOptions {
        entity?: INameRelationEntity;
    }

}