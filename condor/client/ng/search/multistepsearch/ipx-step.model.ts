export type Step = {
    id: number;
    /**
     * @default false
     */
    isDefault?: boolean;
    operator: string;
    selected: boolean;
    isAdvancedSearch?: boolean;
    topicsData?: Array<TopicData>;
};

export type TopicData = {
    topicKey: string;
    formData: any;
    filterData?: any;
};