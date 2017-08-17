require_relative "refresh_spec_common"

describe ManageIQ::Providers::Openstack::CloudManager::Refresher do
  include Openstack::RefreshSpecCommon

  before(:each) do
    setup_ems('11.22.33.44', 'password_2WpEraURh')
    @environment = :liberty
  end

  it "will perform a full refresh against RHOS #{@environment}" do
    2.times do # Run twice to verify that a second run with existing data does not change anything
      with_cassette(@environment, @ems) do
        EmsRefresh.refresh(@ems)
        EmsRefresh.refresh(@ems.network_manager)
        EmsRefresh.refresh(@ems.cinder_manager)
        EmsRefresh.refresh(@ems.swift_manager)
      end

      assert_common
    end
  end

  context "when configured with skips" do

    it "will not parse the ignored items" do
      with_cassette(@environment, @ems) do
        EmsRefresh.refresh(@ems)
        EmsRefresh.refresh(@ems.network_manager)
        EmsRefresh.refresh(@ems.cinder_manager)
        EmsRefresh.refresh(@ems.swift_manager)
      end

      assert_with_skips
    end
  end

  context "when using an admin account for fast refresh" do
    it "will perform a fast full refresh against RHOS #{@environment}" do
      ::Settings.ems.ems_openstack.refresh.is_admin = true
      2.times do
        with_cassette("#{@environment}_fast_refresh", @ems) do
          EmsRefresh.refresh(@ems)
          EmsRefresh.refresh(@ems.network_manager)
          EmsRefresh.refresh(@ems.cinder_manager)
          EmsRefresh.refresh(@ems.swift_manager)
        end

        assert_common
      end
      ::Settings.ems.ems_openstack.refresh.is_admin = false
    end
  end

  it "will perform a fast full legacy refresh against RHOS #{@environment}" do
    ::Settings.ems.ems_openstack.refresh.is_admin = true
    ::Settings.ems.ems_openstack.refresh.inventory_object_refresh = false
    2.times do
      with_cassette("#{@environment}_legacy_fast_refresh", @ems) do
        EmsRefresh.refresh(@ems)
        EmsRefresh.refresh(@ems.network_manager)
        EmsRefresh.refresh(@ems.cinder_manager)
        EmsRefresh.refresh(@ems.swift_manager)
      end

      assert_common
    end
    ::Settings.ems.ems_openstack.refresh.is_admin = false
    ::Settings.ems.ems_openstack.refresh.inventory_object_refresh = true
  end

  context "targeted refresh" do
    it "will perform a targeted VM refresh against RHOS #{@environment}" do
      # EmsRefreshSpec-PoweredOn
      vm_target = ManagerRefresh::Target.new(:manager => @ems, :association => :vms, :manager_ref => {:ems_ref => "ca4f3a16-bae3-4407-83e9-f77b28af0f2b"})
      2.times do # Run twice to verify that a second run with existing data does not change anything
        with_cassette("#{@environment}_vm_targeted_refresh", @ems) do
          EmsRefresh.refresh(vm_target)
          assert_targeted_vm("EmsRefreshSpec-PoweredOn", :power_state => "on",)
        end
      end
    end
  end
end
