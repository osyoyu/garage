require 'spec_helper'

describe 'Field loading API' do
  let(:application) { create(:application) }
  let(:user) { create(:user) }
  let(:post) { create(:post, :user => user) }
  let(:location_with_query) { location + '?' + query }
  let(:query) { '' }

  before do
    with_access_token_header(client_is_authorized(application, user).token)
  end

  subject {
    get location_with_query
    body
  }

  describe '/post' do
    let(:location) { "/posts/#{post.id}" }

    context 'with no query' do
      it 'has basic fields' do
        subject.should have_key 'id'
        subject.should have_key 'title'
        subject.should_not have_key 'user'
      end
    end

    context 'with * query' do
      let(:query) { 'fields=*' }
      it 'has all fields' do
        subject.should have_key 'id'
        subject.should have_key 'title'
        subject.should have_key 'user'
      end
    end

    context 'with fields=id query' do
      let(:query) { 'fields=id' }
      it 'has only id field' do
        subject.should have_key 'id'
        subject.should_not have_key 'title'
      end
    end

    context 'with fields=id,title query' do
      let(:query) { 'fields=id,title' }
      it 'has only id field' do
        subject.should have_key 'id'
        subject.should have_key 'title'
        subject.should_not have_key 'user'
      end
    end

    context 'with fields=user query' do
      let(:query) { 'fields=user' }
      it 'has default fields for user' do
        subject.should have_key 'user'
        subject['user'].should have_key 'id'
        subject['user'].should have_key 'name'
      end
    end

    context 'with fields=user[id] query' do
      let(:query) { 'fields=user[id]' }
      it 'has only the specified fields for user' do
        subject.should have_key 'user'
        subject['user'].should have_key 'id'
        subject['user'].should_not have_key 'name'
      end
    end
  end

  describe 'cached resources' do
    let(:location) { "/users/#{user.id}/posts" }

    before do
      create(:post, user: user)
    end

    context 'with no query' do
      it 'has all fields' do
        subject.first.should have_key 'id'
        subject.first.should have_key 'title'
      end
    end

    context 'with fields=id query' do
      let(:query) { 'fields=id' }
      it 'has id fields' do
        subject.first.should have_key 'id'
        subject.first.should_not have_key 'title'
      end
    end

    context 'with no query first, then access with fields' do
      it 'has only fields' do
        subject.first.should have_key 'title'
        get(location + '?fields=id')
        body.first.should_not have_key 'title'
      end
    end
  end

  describe 'Bad fields query' do
    let(:location) { '/posts' }
    subject {
      get location_with_query
      status
    }

    context 'with badly formatted id' do
      let(:query) { 'fields=[]' }
      it 'results in 400 Bad Request' do
        subject.should == 400
      end
    end
  end
end
